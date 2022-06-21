module GGEV
  GEMNAME = "ggev"
  DEFAULT_CONFIG_FILE = File::expand_path("~/.config/ggev/config.yaml")
  DEFAULT_HOME_PATH = File::expand_path("~/.ggev")
  REPO_PATH = "#{DEFAULT_HOME_PATH}/repo"
  DEFAULT_ENC_CIPHER = "aes-128-cbc"

  BRANCH_MASTER_DECRYPT = "master-decrypt"
  BRANCH_LOCAL = "local"
end

