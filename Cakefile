{exec, spawn} = require 'child_process'

handleError = (err) ->
  if err
    console.log "\n\033[1;36m=>\033[1;37m Remember that you need to install coffee-script\033[0;37m\n"
    console.log err.stack

print = (data) -> console.log data.toString().trim()

task 'build', 'Compile riak-js Coffeescript source to Javascript', ->
  exec 'mkdir -p lib && ln -sf ../src/riak.desc lib && coffee -c -o lib src', handleError

task 'clean', 'Remove generated Javascripts', ->
  exec 'rm -fr lib', handleError

task 'dev', 'Continuous compilation', ->
  coffee = spawn 'coffee', '-wc --bare -o lib src'.split(' ')

  coffee.stdout.on 'data', print
  coffee.stderr.on 'data', print
