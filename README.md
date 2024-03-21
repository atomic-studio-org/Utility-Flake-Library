# Utility flake for Atomic Studio

This flake provides some attributes for any Atomic Studio project
so that there will be less duplication between repos

For example: There are some scripts like `cosign-generate`
that are useful on any repository that needs cosign,
that needs to be updated in each one, thus making this very annoying to maintain.
This repo's objective is to make this as least annoying as possible.

You can consume this repo in your other projects by running the following command:

```shell
# This should initialize a github repo with default things
nix flake init --template github:atomic-studio-org/Utility-Flake-Library#
```

Any other attibute is specified in the nix flake and it can be imported
in your other flakes!
