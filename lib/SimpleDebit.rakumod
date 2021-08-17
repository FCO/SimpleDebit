use Cro::HTTP::Client;
use SimpleDebit::Client;
use SimpleDebit::Transaction;

my %*SUB-MAIN-OPTS = :named-anywhere;

my @fib = 0, 1, &[+] ... *;

sub write-file($file, @objs where .all ~~ SimpleDebit::Client) is export {
    note "Writing file '$file.path()'" if $*verbose;
    $file.say: "iban,amount_in_pence";
    my UInt $lines = 0;
    for @objs {
        if .amount {
            $file.say: "{ .iban },{ .amount }";
            $lines++
        }
    }
    note "$lines lines writen" if $*verbose
}

sub get-list-of-clients is export {
    CATCH {
        when X::Cro::HTTP::Error {
            if .response.status == 404 {
                note "\o033[31mERROR:\o033[m Client list not found." unless $*quiet
            } else {
                note "\o033[31mERROR:\o033[m Unexpected error trying to fetch client list: { .message }" unless $*quiet
            }
        }
        when X::TypeCheck::Assignment {
            die "\o033[31mERROR:\o033[m Server has answered unexpected data.";
        }
    }
    note "Getting list of clients" if $*verbose;
    my $client-request = await $*ua.get: "merchants";
    my Str @clients = Array[Str].new: await $client-request.body;
    note "Got a list of { +@clients } items" if $*verbose;
    @clients
}

sub get-clients(@clients, UInt $retry = 0) is export {
    my @errors;
    my @objs = @clients.race(batch => 1, degree => 4).map: -> Str $id {
        CATCH {
            when X::Cro::HTTP::Error::Client {
                if $*retry-on-client-error && $retry {
                    note "\o033[33;1mWARNING:\o033[m Client $id not found (\o033[32;2mgoing to retry it\o033[m)." unless $*quiet;
                    @errors.push: $id
                } else {
                    note "\o033[31mERROR:\o033[m Client $id not found." unless $*quiet;
                }
                next
            }
            when X::Cro::HTTP::Error::Server {
                if $retry {
                    note "\o033[33;1mWARNING:\o033[m Unexpected error trying to fetch client $id (\o033[32;2mgoing to retry it\o033[m): { .message }" unless $*quiet;
                    @errors.push: $id
                } else {
                    note "\o033[31;1mERROR:\o033[m Unexpected error trying to fetch client $id (\o033[33;1mno retry\o033[m): { .message }" unless $*quiet;
                }
                next
            }
        }
        note "Getting data of user $id" if $*verbose;
        my $resp = await $*ua.get: "merchants/$id";
        do with await $resp.body -> (Str :$id, Str :$iban, :%discount where { .<minimum_transaction_count> ~~ Int && .<fees_discount> ~~ Int }, :@transactions) {
            SimpleDebit::Client.new:
                :$id,
                :$iban,
                :min-trans(%discount<minimum_transaction_count>),
                :fee-discount(%discount<fees_discount>),
                :transactions(@transactions.map: -> ( Int :$amount, Int :$fee ) { SimpleDebit::Transaction.new: :$amount, :$fee })
        }
    }
    .take for @objs;
    if @errors {
        sleep @fib[$++];
        get-clients @errors, $retry - 1
    }
}
