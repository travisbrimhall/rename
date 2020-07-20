NC='\033[0m' # No Color
blue='\e[38;5;81m'
red='\033[01;31m'
green='\033[01;32m'
yellow='\033[01;33m'
purple='\033[01;35m'
cyan='\033[01;36m'
white='\033[01;37m'
bold='\033[1m'
underline='\033[4m'
DIR=$(readlink -f .)

clear
echo
printf "${bold}what do u currently call your personal fork remotes?
(most folks use the default ${blue}origin${NC}${bold}) ${NC}\n"
read -p $'\e[38;5;81mremote name: \e[0m ' REMOTE
echo
printf "${bold}cool, and what are we going to rename master to?${NC}\n"
printf "(we think ${bold}${blue}base${NC} is a good standard) \n"
read -p $'\e[38;5;81mnew branch name: \e[0m ' BRANCH
echo
echo
echo "alright, we're going to run through each directory here looking for git projects"
echo "if we find one without a base branch, we'll create, and push it to ${REMOTE}"

for repo in $DIR/*; do
  if [[ ! -d "$repo" || ! -e "$repo/.git" ]]; then
    continue
  fi
  echo
  printf "${purple}========================================${NC} \n"
  echo
  cd $repo
  currentDirName=${PWD##*/}
  printf "${bold}working on ${blue}$currentDirName${NC}${bold}...${NC}\n"
  
  git ls-remote --exit-code --heads  git@github.com:travisbrimhall/$currentDirName.git $BRANCH
  
  
  if [ $? != 0 ] # If we don't already have a branch w that name
  then
    git pull --rebase --autostash $REMOTE master # check for the latest

    # TODO: add a check for if conflicts
    git show-ref --verify --quiet refs/heads/$BRANCH
    if [ $? == 0 ] # You already got a local base branch, but haven't pushed
    then
      printf "${red}ERROR:${NC}\n"
      printf "${red}woah, looks like you already have a local base branch, but haven't pushed${NC} \n"
      printf "${red}go back to this project and figure out what's up${NC}"
    else
      git branch -m master base && git push -u $REMOTE base 
    fi
  else
    pwd
    printf "oh sweet, "
    printf "${green}you've already got a $BRANCH branch on the remote $REMOTE ${NC}\n"
    printf "${bold}skipping to the next repo...${NC}\n"
  fi
done;
