use SimpleDebit::Transaction;
unit class SimpleDebit::Client;

has Str $.id           is required;
has Str $.iban         is required;
has Int $.min-trans    is required;
has Int $.fee-discount is required;
has     @.transactions where .all ~~ SimpleDebit::Transaction;
has Int $.amount       = self!calc-amount;

method !calc-amount {
    given [+] @!transactions>>.transfer-amount -> Int $amount is copy {
        $amount -= floor $amount / 100 * $!fee-discount if @!transactions >= $!min-trans;
        $amount
    }
}
