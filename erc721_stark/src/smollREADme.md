### Significance of lib.cairo existence and name convention 

- lib.cairo as the Crate Root: In Cairo (and Rust, which Cairo's module system is heavily inspired by), lib.cairo is the conventional name for the root file of a library crate. When you compile your Cairo project, scarb (the Cairo build tool) looks for this file as the starting point.

- lib.cairo defines the top-level structure: lib.cairo is like the table of contents for your entire library. It tells the compiler what are the main, publicly exposed modules or contracts your library provides. In your case, it says "I provide an Erc721Nft (which you've called Erc721Nft in your code example, but let's assume it corresponds to the Erc721Nft module declaration in lib.cairo) and some components."

- Modules within modules are encapsulated: Once you enter a module (like Erc721Nft), anything declared inside that module, unless explicitly marked pub and intended for external use from that module, remains internal to that module.

- use statements are for importing, not declaring: The use statements within Erc721Nft (e.g., use contracts::components::Counter::CounterComponent;) are importing external modules or traits into the current scope of YourCollectible. They are not declaring new top-level modules for your library. They're saying, "I need to use these existing definitions from other places to build this contract."

- While sending arguments as byte-array use ->      '" "'

  example cli command 

  ```
  sncast --profile=devnet invoke --contract-address=$(ADDRESS) --function=$(FUNC) --arguments $(OWNER),'"$(IPFS_HASH)"'
  ```