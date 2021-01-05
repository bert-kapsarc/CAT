# `MultiSigWallet`

Multisignature wallet - Allows multiple parties to agree on transactions before execution.

# Functions:

- [`fallback()`](#MultiSigWallet-fallback--)

- [`constructor(address[] _owners, uint256 _required)`](#MultiSigWallet-constructor-address---uint256-)

- [`addOwner(address owner)`](#MultiSigWallet-addOwner-address-)

- [`removeOwner(address owner)`](#MultiSigWallet-removeOwner-address-)

- [`replaceOwner(address owner, address newOwner)`](#MultiSigWallet-replaceOwner-address-address-)

- [`changeRequirement(uint256 _required)`](#MultiSigWallet-changeRequirement-uint256-)

- [`submitTransaction(address destination, uint256 value, bytes data)`](#MultiSigWallet-submitTransaction-address-uint256-bytes-)

- [`confirmTransaction(uint256 transactionId)`](#MultiSigWallet-confirmTransaction-uint256-)

- [`revokeConfirmation(uint256 transactionId)`](#MultiSigWallet-revokeConfirmation-uint256-)

- [`executeTransaction(uint256 transactionId)`](#MultiSigWallet-executeTransaction-uint256-)

- [`isConfirmed(uint256 transactionId)`](#MultiSigWallet-isConfirmed-uint256-)

- [`getConfirmationCount(uint256 transactionId)`](#MultiSigWallet-getConfirmationCount-uint256-)

- [`getTransactionCount(bool pending, bool executed)`](#MultiSigWallet-getTransactionCount-bool-bool-)

- [`getOwners()`](#MultiSigWallet-getOwners--)

- [`getConfirmations(uint256 transactionId)`](#MultiSigWallet-getConfirmations-uint256-)

- [`getTransactionIds(uint256 from, uint256 to, bool pending, bool executed)`](#MultiSigWallet-getTransactionIds-uint256-uint256-bool-bool-)

# Events:

- [`Confirmation(address sender, uint256 transactionId)`](#MultiSigWallet-Confirmation-address-uint256-)

- [`Revocation(address sender, uint256 transactionId)`](#MultiSigWallet-Revocation-address-uint256-)

- [`Submission(uint256 transactionId)`](#MultiSigWallet-Submission-uint256-)

- [`Execution(uint256 transactionId)`](#MultiSigWallet-Execution-uint256-)

- [`ExecutionFailure(uint256 transactionId)`](#MultiSigWallet-ExecutionFailure-uint256-)

- [`Deposit(address sender, uint256 value)`](#MultiSigWallet-Deposit-address-uint256-)

- [`OwnerAddition(address owner)`](#MultiSigWallet-OwnerAddition-address-)

- [`OwnerRemoval(address owner)`](#MultiSigWallet-OwnerRemoval-address-)

- [`RequirementChange(uint256 required)`](#MultiSigWallet-RequirementChange-uint256-)

# fallback

##Fallback function allows to deposit ether.

### `fallback()` {#MultiSigWallet-fallback--}

# constructor

##Contract constructor sets initial owners and required number of confirmations.

### `constructor(address[] _owners, uint256 _required)` {#MultiSigWallet-constructor-address---uint256-}

## Parameters:

- `_owners`: List of initial owners.

- `_required`: Number of required confirmations.

# addOwner

##Allows to add a new owner. Transaction has to be sent by wallet.

### `addOwner(address owner)` {#MultiSigWallet-addOwner-address-}

## Parameters:

- `owner`: Address of new owner.

# removeOwner

##Allows to remove an owner. Transaction has to be sent by wallet.

### `removeOwner(address owner)` {#MultiSigWallet-removeOwner-address-}

## Parameters:

- `owner`: Address of owner.

# replaceOwner

##Allows to replace an owner with a new owner. Transaction has to be sent by wallet.

### `replaceOwner(address owner, address newOwner)` {#MultiSigWallet-replaceOwner-address-address-}

## Parameters:

- `owner`: Address of owner to be replaced.

- `newOwner`: Address of new owner.

# changeRequirement

##Allows to change the number of required confirmations. Transaction has to be sent by wallet.

### `changeRequirement(uint256 _required)` {#MultiSigWallet-changeRequirement-uint256-}

## Parameters:

- `_required`: Number of required confirmations.

# submitTransaction

##Allows an owner to submit and confirm a transaction.

### `submitTransaction(address destination, uint256 value, bytes data) → uint256 transactionId` {#MultiSigWallet-submitTransaction-address-uint256-bytes-}

## Parameters:

- `destination`: Transaction target address.

- `value`: Transaction ether value.

- `data`: Transaction data payload.

## Return Values:

- Returns transaction ID.

# confirmTransaction

##Allows an owner to confirm a transaction.

### `confirmTransaction(uint256 transactionId)` {#MultiSigWallet-confirmTransaction-uint256-}

## Parameters:

- `transactionId`: Transaction ID.

# revokeConfirmation

##Allows an owner to revoke a confirmation for a transaction.

### `revokeConfirmation(uint256 transactionId)` {#MultiSigWallet-revokeConfirmation-uint256-}

## Parameters:

- `transactionId`: Transaction ID.

# executeTransaction

##Allows anyone to execute a confirmed transaction.

### `executeTransaction(uint256 transactionId)` {#MultiSigWallet-executeTransaction-uint256-}

## Parameters:

- `transactionId`: Transaction ID.

# isConfirmed

##Returns the confirmation status of a transaction.

### `isConfirmed(uint256 transactionId) → bool` {#MultiSigWallet-isConfirmed-uint256-}

## Parameters:

- `transactionId`: Transaction ID.

## Return Values:

- Confirmation status.

# getConfirmationCount

##Returns number of confirmations of a transaction.

### `getConfirmationCount(uint256 transactionId) → uint256 count` {#MultiSigWallet-getConfirmationCount-uint256-}

## Parameters:

- `transactionId`: Transaction ID.

## Return Values:

- Number of confirmations.

# getTransactionCount

##Returns total number of transactions after filers are applied.

### `getTransactionCount(bool pending, bool executed) → uint256 count` {#MultiSigWallet-getTransactionCount-bool-bool-}

## Parameters:

- `pending`: Include pending transactions.

- `executed`: Include executed transactions.

## Return Values:

- Total number of transactions after filters are applied.

# getOwners

##Returns list of owners.

### `getOwners() → address[]` {#MultiSigWallet-getOwners--}

## Return Values:

- List of owner addresses.

# getConfirmations

##Returns array with owner addresses, which confirmed transaction.

### `getConfirmations(uint256 transactionId) → address[] _confirmations` {#MultiSigWallet-getConfirmations-uint256-}

## Parameters:

- `transactionId`: Transaction ID.

## Return Values:

- Returns array of owner addresses.

# getTransactionIds

##Returns list of transaction IDs in defined range.

### `getTransactionIds(uint256 from, uint256 to, bool pending, bool executed) → uint256[] _transactionIds` {#MultiSigWallet-getTransactionIds-uint256-uint256-bool-bool-}

## Parameters:

- `from`: Index start position of transaction array.

- `to`: Index end position of transaction array.

- `pending`: Include pending transactions.

- `executed`: Include executed transactions.

## Return Values:

- Returns array of transaction IDs.

# Event `Confirmation(address sender, uint256 transactionId)` {#MultiSigWallet-Confirmation-address-uint256-}

No description

# Event `Revocation(address sender, uint256 transactionId)` {#MultiSigWallet-Revocation-address-uint256-}

No description

# Event `Submission(uint256 transactionId)` {#MultiSigWallet-Submission-uint256-}

No description

# Event `Execution(uint256 transactionId)` {#MultiSigWallet-Execution-uint256-}

No description

# Event `ExecutionFailure(uint256 transactionId)` {#MultiSigWallet-ExecutionFailure-uint256-}

No description

# Event `Deposit(address sender, uint256 value)` {#MultiSigWallet-Deposit-address-uint256-}

No description

# Event `OwnerAddition(address owner)` {#MultiSigWallet-OwnerAddition-address-}

No description

# Event `OwnerRemoval(address owner)` {#MultiSigWallet-OwnerRemoval-address-}

No description

# Event `RequirementChange(uint256 required)` {#MultiSigWallet-RequirementChange-uint256-}

No description
