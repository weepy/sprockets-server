Sprocket Server
====

This is a simple server based on sinatra to serve javascript files and resolve dependencies using the Sprockets library.

This allows javascript to be tested and modularized in a similar form to ruby gems. This modularity allows for a much improved reusability.

To run:

<code>rupy app.rb</code>

Or add to passenger pane (config.ru supplied)

Settings
----

settings.rb provides 2 settings 

:load_paths => the paths to load the Sprockets from
:cache => name of an internal file that is used to inform Sprockts which files to load

Divergence from Sprockets Gem
---

The server doesn't use any concatenation and instead provides the javascript in distinct files. It uses Hpricot to rewrite any html files to include the relevant scripts.

Routes
----

/ - The root of the server will display any html files in each of the load paths - which are assumed to be tests
/*.html - Any html file is loaded and rewritten according to the dependencies
/*.* - anything else is simply located and served ( it will search each of the load paths)


