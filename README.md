# SCM Repository Handler

The scripts are made to manage repositories through different scm types.

## Supported functions

Repository creation (empty or with a default README)
Repository deletion
Repository default branch setting
Repository visibility (private, public, internal...)

## Supported repository

Official versions of :

* [Github](https://github.com/) (take a guess about how this repository was created ;-) )
* [Gitlab](https://gitlab.com)
* [Bitbucket](https://bitbucket.org)

## Usage

Set the informations as environment variable or through `.env.dist` file.

Copy the `.env.dist` as `.env` file and update it according to your informations (do not forget to encode the token data as base64)

See the associated help for informations about available options.

Be careful as for Bitbucket API it is the username and not the login name used to access through the UI (See : Personnal settings > Account settings > Username for the valid field).
