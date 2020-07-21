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
echo "alrighty, we're going to run through each directory here looking for git projects."
echo "if we find one, we'll hop in, make a new branch with the name you choose, and push it to your remote."
echo "after that you'll have to manually set the new branch to be the default branch via github settings."
echo "but before we run the automation, we need a few infoz from you so...."
echo
printf "${bold}what's the name of your github account?${NC}\n"
read -p $'\e[38;5;81mgithub account name: \e[0m ' GITHUBUSER
echo
printf "${bold}what do u call the remotes we're going to be working with?
(most folks use the default ${blue}origin${NC}${bold}) ${NC}\n"
read -p $'\e[38;5;81mremote name: \e[0m ' REMOTE
echo
printf "${bold}cool, and what are we going to rename master to?${NC}\n"
printf "(we think ${bold}${blue}base${NC} is a good standard) \n"
read -p $'\e[38;5;81mnew branch name: \e[0m ' BRANCH
echo
echo

# A counter for printing a summary at the bottom
ALREADY_COUNT=0
SUCCESSFUL_COUNT=0
FAILED_COUNT=0
FAILED_REPOS=()

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
  
  git ls-remote --exit-code --heads  git@github.com:$GITHUBUSER/$currentDirName.git $BRANCH

  if [ $? != 0 ] # If we don't already have a branch w that name
  then
    git pull --rebase --autostash $REMOTE master # check for the latest

    # TODO: add a check for if conflicts
    git show-ref --verify --quiet refs/heads/$BRANCH
    if [ $? == 0 ] # You already got a local base branch, but haven't pushed
    then
      ((FAILED_COUNT=FAILED_COUNT+1))
      FAILED_REPOS+=("${currentDirName}")
      printf "${red}ERROR: looks like you already have a local $BRANCH branch, but haven't pushed${NC}\n"
    else
      ((SUCCESSFUL_COUNT=SUCCESSFUL_COUNT+1))
      git branch -m master base && git push -u $REMOTE base 
    fi
  else
    pwd
    ((ALREADY_COUNT=ALREADY_COUNT+1))
    printf "oh sweet, "
    printf "${green}you've already got a $BRANCH branch on the remote $REMOTE ${NC}\n"
    printf "${bold}skipping to the next repo...${NC}\n"
  fi
done;
echo
echo
printf "${purple}========================================${NC} \n"
printf "${purple}_______________ SUMMARY ________________${NC} \n"
printf "${purple}========================================${NC} \n"
echo
if [ $SUCCESSFUL_COUNT != 0 ]
  then
  printf "${green}success!${NC} we created and pushed a ${bold}new $BRANCH branch${NC} to ${bold}${green}$SUCCESSFUL_COUNT repos${NC} on ${bold}$REMOTE${NC}\n"
  echo
fi
if [ $ALREADY_COUNT != 0 ]
  then
  printf "${blue}the good news:${NC} you ${bold}${green}already had${NC} a ${bold}$BRANCH${NC} in ${bold}${green}$ALREADY_COUNT repos${NC}. so no action taken there.\n"
  echo
fi
if [ $FAILED_COUNT != 0 ]
  then
  printf "${red}the bad news:${NC} we ${bold}${red}failed${NC} to make or push a $BRANCH in ${bold}${red}$FAILED_COUNT repos${NC}.\n"
  printf "go back and take a look at ${bold}${FAILED_REPOS[@]}${NC} to see what went wrong. godspeed."
fi
echo