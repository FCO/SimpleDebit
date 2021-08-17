unit class SimpleDebit::Transaction;

has Int $.amount is required;
has Int $.fee    is required;

method transfer-amount { $!amount - $!fee }
