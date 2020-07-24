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

# 
#
# Intro Section: gather variables from user input
# 
# 
clear
echo
echo "alrighty, we're going to run through each directory here looking for git projects."
echo "if we find one, we'll hop in, make a new branch with the name you choose, and push it to your remote."
echo "after that you'll have to manually set the new branch to be the default branch via github settings."
echo "but before we run the automation, we need a few infoz from you so...."

# echo
# printf "${bold}we need to know where to look.${NC}\n"
# printf "${bold}what's the name of your github account?${NC}\n"
# read -p $'\e[38;5;81mgithub account name: \e[0m ' GITHUBUSER #looks weird because these read commands can't take color vars
GITHUBUSER=travisbrimhall # TODO: remove

# echo
# printf "${bold}what do u call the remotes we're going to be working with?
# (most folks use the default ${blue}origin${NC}${bold}) ${NC}\n"
# read -p $'\e[38;5;81mremote name: \e[0m ' REMOTE
REMOTE=origin # TODO: remove

# echo
# printf "${bold}cool, and what are we going to rename master to?${NC}\n"
# printf "(we think ${bold}${blue}base${NC} is a good standard) \n"
# read -p $'\e[38;5;81mnew branch name: \e[0m ' NEW_BRANCH
NEW_BRANCH=base #TODO: remove
echo
echo

# Before we go in the loop, create counters for printing a summary at the bottom
ALREADY_COUNT=0
SUCCESSFUL_COUNT=0
FAILED_COUNT=0
FAILED_REPOS=()
#TODO: add successful repos array?

for repo in ./*; do #This looks at every file in the current directory

  if [[ ! -d "$repo" || ! -e "$repo/.git" ]]; then # If the file is not a directory or doesn't contain a .git file
    continue # skip to the next item in the iteration
  fi

  echo
  printf "${purple}========================================${NC} \n"
  echo
  cd $repo # Now we're sure that we're in a git repo
  CURRENT_DIR_NAME=${PWD##*/}

  printf "${bold}working on ${blue}$CURRENT_DIR_NAME${NC}${bold}...${NC}\n"
  # list if there is a branch on the remote with the target name, and give the command an exit code that 
  # we can check as true or false
  git ls-remote --exit-code --heads  git@github.com:$GITHUBUSER/$CURRENT_DIR_NAME.git $NEW_BRANCH 

  if [ $? != 0 ] # If we don't already have a branch w that name on the remote
  then

    #TODO: CHECK FOR BRANCH PROTECTIONS
    
    git pull --rebase --autostash $REMOTE master # get the latest from the remote master branch

    git show-ref --verify --quiet refs/heads/$NEW_BRANCH # do we have a local branch w the target name?
    if [ $? == 0 ] # if yes, we do have a local branch
    then
      ((FAILED_COUNT=FAILED_COUNT+1))
      FAILED_REPOS+=("${CURRENT_DIR_NAME}")
      printf "${red}ERROR: looks like you already have a local $NEW_BRANCH branch, but haven't pushed${NC}\n"
      # TODO: if you have a local branch but haven't pushed, then rebase w master and try to push it.
    else
      git branch -m master base && git push -u $REMOTE base 
      # TODO: what if this fails? like for permissions? conflicts?
      ((SUCCESSFUL_COUNT=SUCCESSFUL_COUNT+1))
    fi
  else #if we DO already have a branch with that name on the remote
    ((ALREADY_COUNT=ALREADY_COUNT+1))
    printf "oh sweet, "
    printf "${green}you've already got a $NEW_BRANCH branch on the remote $REMOTE ${NC}\n"
    printf "${bold}skipping to the next repo...${NC}\n"
  fi
done; # end iterating over repos


echo
echo
printf "${purple}========================================${NC} \n"
printf "${purple}_______________ SUMMARY ________________${NC} \n"
printf "${purple}========================================${NC} \n"
echo

#TODO: make path/message for if we don't find any git repos

if [ $SUCCESSFUL_COUNT != 0 ]
  then
  printf "${green}success!${NC} we created and pushed a ${bold}new $NEW_BRANCH branch${NC} to ${bold}${green}$SUCCESSFUL_COUNT repos${NC} on ${bold}$REMOTE${NC}\n"
  echo
fi

if [ $ALREADY_COUNT != 0 ]
  then
  printf "${blue}the good news:${NC} you ${bold}${green}already had${NC} a ${bold}$NEW_BRANCH${NC} in ${bold}${green}$ALREADY_COUNT repos${NC}. so no action taken there.\n"
  echo
fi

if [ $FAILED_COUNT != 0 ]
  then
  printf "${red}the bad news:${NC} we ${bold}${red}failed${NC} to make or push a $NEW_BRANCH in ${bold}${red}$FAILED_COUNT repos${NC}.\n"
  printf "go back and take a look at ${bold}${FAILED_REPOS[@]}${NC} to see what went wrong. godspeed."
fi

if [[ $SUCCESSFUL_COUNT == 0 && $FAILED_COUNT == 0 && $ALREADY_COUNT == 0 ]]
  then
  printf "${bold}${red}Looks like there are no git repos in this folder. ${NC} \n"
  printf "You are currenlty in ${bold}${blue}${PWD}${NC}"
  echo
fi

echo