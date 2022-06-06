#!/usr/bin/ruby

require "logger"
require "yaml"

# Constants
DEFAULT_CONFIG_FILE="./config/ggev.yaml"
DEFAULT_HOME_PATH=File::expand_path("~/.ggev")
REPO_PATH="#{DEFAULT_HOME_PATH}/repo"
DEFAULT_ENC_CIPHER="aes-128-cbc"

# Functions
def usage()
  puts "Usage: #{$PROGRAM_NAME} [command]"
  puts ""
  puts "Commands:"
  puts " init"
  puts " push"
  puts " pull"
end

def run_cmd_with_exitstatus(cmd)
  logger = Logger.new(STDOUT)
  if not system(cmd) 
    return false, $?.exitstatus
  end
  return true, $?.exitstatus
end

def run_cmd(cmd)
  ok, es = run_cmd_with_exitstatus(cmd)
  return ok
end

def must_run_cmd(cmd)
  run_cmd(cmd) or exit
end

# Main
logger = Logger::new(STDOUT)

if ARGV.length < 1
  usage()
  exit
end
cmd = ARGV[0]

## Load config
cfg = YAML::load_file(DEFAULT_CONFIG_FILE)

## Prepare project directories
if not Dir::exists?(DEFAULT_HOME_PATH)
  logger.info("#{DEFAULT_HOME_PATH} not found, creating ...")
  Dir.mkdir(DEFAULT_HOME_PATH)
end

if not Dir::exists?(REPO_PATH)
  logger.info("Cloning repo ...")
  must_run_cmd("git clone #{cfg["repo"]["remote"]} #{REPO_PATH}")
end

## Process commands
if cmd=="init"
  puts "TODO"
end

if cmd=="push"
  cfg["modules"].each { |mod|
    puts "Processing module #{mod["name"]} ..."

    mod_path = "#{REPO_PATH}/#{mod["name"]}"
    if not Dir::exists?(mod_path)
      FileUtils::mkdir_p(mod_path)
    end

    mod["files"].each { |origin_file_path|
      origin_file_path = File::expand_path(origin_file_path)
      file_name = File::basename(origin_file_path)
      cache_file_path = "#{mod_path}/#{file_name}"

      logger.info("#{origin_file_path} =(enc)=> #{cache_file_path} ...")
      must_run_cmd("openssl enc -#{DEFAULT_ENC_CIPHER} -base64 -k #{cfg["encrypt"]["key"]} -in #{origin_file_path} -out #{cache_file_path}")
    }
  }

  ### Cipher
  File::write("#{REPO_PATH}/.cipher", "#{DEFAULT_ENC_CIPHER}")

  ### Commit repo
  Dir::chdir(REPO_PATH) {
    must_run_cmd("git add -A")
    must_run_cmd("git -P diff --cached --stat")
    must_run_cmd("git commit -a -m 'auto-commit by ggev'")
    must_run_cmd("git push origin master")
  }
end

if cmd=="pull"
  ### Pull resp
  Dir::chdir(REPO_PATH) {
    must_run_cmd("git fetch origin master")
    ok, ec = run_cmd_with_exitstatus("git diff --exit-code --stat origin/master")

    if ok
      # Unchanged
      logger.info("Unchanged")
      return
    end

    # Other error
    if ec!=1 
      return
    end

    # ec==1
    # Something changed
    must_run_cmd("git merge origin/master ")
  }

  cipher = File::read("#{REPO_PATH}/.cipher")

  cfg["modules"].each { |mod|
    puts "Processing module #{mod["name"]} ..."

    mod_path = "#{REPO_PATH}/#{mod["name"]}"
    mod["files"].each { |origin_file_path|
      origin_file_path = File::expand_path(origin_file_path)
      file_name = File::basename(origin_file_path)
      cache_file_path = "#{mod_path}/#{file_name}"

      logger.info("#{cache_file_path} =(enc)=> #{origin_file_path} ...")
      must_run_cmd("openssl enc -#{cipher} -base64 -k #{cfg["encrypt"]["key"]} -d -in #{cache_file_path} -out #{origin_file_path}")
    }
  }
end
