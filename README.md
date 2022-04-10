# Episode Flag

A command-line podcast searching tool.

<img width="1280" alt="episode_flag" src="https://user-images.githubusercontent.com/1578054/162627467-a23415b6-433f-4d9a-80af-c95010edc022.png">


## What?

A tool for searching the titles and descriptions of recent podcast episodes you subscribe to. Provide the OPML file from your podcast client, along with a search term and how far back you want to search, and get a list of matching episodes.

This was a quick script written mainly to play with the new Ruby Async gem.

It is currently just a command-line script, but it could be improved by abstracting the core for use in a web service that allows users to upload an OPML file, set their search terms, and get a weekly email with matching episodes.

## Why?

If you follow a lot of people on Twitter you probably don't attempt to read every tweet, you might just drop in occasionally and read recent tweets. Like any social network the service will also attempt to promote important messages, like those from close friends, into your feed.

If you subscribe to dozens or even hundreds of podcasts you get into a similar situation, there's not enough time to listen to them all. There's a need for a tool that can flag up episodes you don't want to miss. This project will attempt to solve that with user-defined rules that can parse recent episode descriptions and regularly flag a set of "unmissable" episodes.

## Use

1. Install Ruby (at least version 3.1)
2. Run `bundle install`
3. Export an OPML file from your podcast app, rename it to "podcasts_opml.xml" and place in the same folder as the script.
4. Run the script with `./episode_flag.rb`
