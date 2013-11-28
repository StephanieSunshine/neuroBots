# set path to app that will be used to configure unicorn, 
# note the trailing slash in this example
@dir = "."

worker_processes 1
working_directory @dir

timeout 120 

# Specify path to socket unicorn listens to, 
# we will use this in our nginx.conf later
#listen "#{@dir}tmp/sockets/unicorn.sock", :backlog => 64

listen 30000
#listen 4002
#listen 4003
#listen 4004

# Set process id path
pid "#{@dir}tmp/pids/controller1.pid"

# Set log file paths
stderr_path "#{@dir}/stderr.log"
stdout_path "#{@dir}/stdout.log"
#stderr_path "/dev/null"
#stdout_path "/dev/null"

preload_app true
GC.respond_to?(:copy_on_write_friendly=) and
GC.copy_on_write_friendly = true


