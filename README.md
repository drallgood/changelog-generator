# Changelog generator
[![CLI](https://github.com/drallgood/changelog-generator/actions/workflows/build.yml/badge.svg)](https://github.com/drallgood/changelog-generator/actions/workflows/build.yml)
[![IntelliJ Plugin](https://github.com/drallgood/changelog-generator/actions/workflows/intellij_build.yml/badge.svg)](https://github.com/drallgood/changelog-generator/actions/workflows/intellij_build.yml)

Generate changelogs (or release notes) in complex, high-frequency projects with ease. 

This project was inspired by [Gitlab's way](https://about.gitlab.com/blog/2018/07/03/solving-gitlabs-changelog-conflict-crisis/) of creating Changelogs.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) 

## Introduction
### WHY?

For simple projects, a simple CHANGELOG.md file or even git commit messages are sufficient to document all significant changes.   

For more complex, multi repository projects, centralized changelogs or release notes are often instituted (e.g in a separate tool or repository). 

However, the more complex a project becomes, the less effective these approaches are.  
Here are a few reasons:

- Commit messages are sometimes too detailed (or not detailed enough). Especially when following an approach of frequent commits
- Single files (like `CHANGELOG.md`) cause merge conflicts if there are multiple people working on the same file.
- Changes in centralized documents (e.g. on Confluence), are often forgotten as they don't reside with the code changes and thus can't be reviewed and merged with the code.
- Fixes to a previous version (e.g. "bugfix" or "maintenance" releases), often mean adapting multiple documents.

That's where Gitlab's approach is great. Each change is encapsulated in a single (or multiple) files. Changelogs/release notes can be generated out of them

### Changelogs vs. Release Notes

[Changelogs](https://en.wikipedia.org/wiki/Changelog) are comprehensive lists of the new features, enhancements, bugs, and other changes in reverse chronological order. Changelogs usually link to specific issues or feature requests within a change management system and also may include links to the developer who supplied the change.

[Release notes](https://en.wikipedia.org/wiki/Release_notes) are a set of documents delivered to customers with the intent to provide a verbose description of the release of a new version of a product or service. These artifacts are generally created by a marketing team or product owner and contain feature summaries, bug fixes, use cases, and other support material. The release notes are used as a quick guide to what changed outside of the user documentation.
**Release notes can be derived from Changlogs.**

## How it works

The process can be described in a few simple steps:

1) Developer places their changes in a separate Changelog JSON file in `/changelogs/` on his branch, e.g. `/changelogs/MyTicket-123.json`
2) Branch gets merged.
3) At some point (e.g. during the CI/CD run, daily, per sprint, per release, ...) the Changelog generator summarizes all changes and appends them to a standard `CHANGELOG.md` file.

Each entry has a predefined type: 
- `security` - A change done due to enhance security 
- `removed` - Functionality or code was removed
- `fixed` - A bug was fixed
- `deprecated` - Functionality or code was deprecated
- `changed` - Functionality was adapted
- `performance` - A change done to improve performance
- `added` - New functionality added
- `other` - Anything else

### File format
Each change is documented in a convenient JSON file.
A file can contain multiple entries, e.g. to add, deprecate and remove at the same time.

Example:

```
[
  {
    "title": "Descriptive text describing what was added",
    "reference": "TICKET-XXXXXX",
    "type": "added"
  }, 
  {
    "title": "Fixed some flaw that would have broken everything when someone called Beetlejuice three times.",
    "reference": "TICKET-XXXXXX",
    "type": "fixed"
  },
]
```

## Tooling
This project provides two ways of generating Changelogs out of the provided files:
- A Gradle task
- A (Swift based) CLI util that allows you to 
	- Generate a changelog for a project
	- Generate changelogs for a set of projects (e.g. for CI)
	- Generate a sample file based on a template
- A IntelliJ Plugin that allows you to
        - Create Changelog files 

### Gradle Task
See `generate.gradle` (TBD)

### CLI
The CLI is swift based and should run on all systems currently supported by Swift (e.g. Linux, macOS, Windows). For convenience we provide a docker container.

It uses a config file to define some common settings. You can either provide the config file location directly to the cli using the `-c <config-file>` option, or provide a default file by placing it at `~/.config/changelog-generator.json`:

```
{
    "gitUrl": "https://gitlab.com",
    "gitAccessToken": "",
    "gitExecutablePath": "/usr/bin/git",
    "gitConnectorType": "Gitlab",
    "ticketBaseUrl":"https://jira.com/browse/"
}
```

The CLI has a help section built-in
```
USAGE: changelog-generator [--config-file <config-file>] [--debug] <subcommand>

OPTIONS:
  -c, --config-file <config-file>
  --debug                 Enable debug logging 
  -h, --help              Show help information.

SUBCOMMANDS:
  create                  Create a changelog JSON file
  check                   Check changelogs for a (set of) project(s)
  generate                Generate Changelogs for a project
  generate-all            Generate Changelogs for all projects
  clear                   Clear changelogs for a (set of) project(s), e.g. to set up for a new version

  See 'changelog-generator help <subcommand>' for detailed help.
 ```

 #### Connectors

 In order to be able to create merge requests, we're providing connectors for different git services.  

 Currently supported:
 - Gitlab (both gitlab.com and gitlab server should work)
 - Github

#### Using docker
 
To run the cli:
```
docker run -ti --rm drallgood/changelog-generator:latest
```

For example:
```
docker run -ti --rm \
-v ~/.gitconfig:/root/.gitconfig \
-v ~/.ssh/known_hosts:/root/.ssh/known_hosts \
-v ~/.ssh/id_rsa:/root/.ssh/id_rsa \
-v  ~/.ssh/id_rsa.pub:/root/.ssh/id_rsa.pub \
-v "$PWD"/projects.json:/projects.json \
-v ~/.config/changelog-generator:/config.json \
drallgood/changelog-generator:latest generate-all -p /projects.json -c /config.json -m --push -b master 1.0.0
```

#### From source

You need to have Swift installed to complile this.

Run
```
swift build -c release
ln -s $PWD/.build/release/changelog-generator /usr/local/bin/
```
