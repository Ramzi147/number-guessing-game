#!/bin/bash
PSQL="psql --username=freecodecamp --dbname=number_guess -X -t --no-align -q -c"

echo 'Enter your username:'
IFS= read -r USERNAME || exit 0
SAFE_NAME=${USERNAME//\'/\'\'}
USER_ID=$($PSQL "SELECT user_id FROM users WHERE username='$SAFE_NAME'")
if [[ -z $USER_ID ]]; then
  USER_ID=$($PSQL "INSERT INTO users(username) VALUES ('$SAFE_NAME') RETURNING user_id")
  echo "Welcome, $USERNAME! It looks like this is your first time here."
else
  STATS=$($PSQL "SELECT COUNT(*), COALESCE(MIN(guesses), 0) FROM games WHERE user_id=$USER_ID")
  IFS='|' read -r PLAYED BEST <<< "$STATS"
  echo "Welcome back, $USERNAME! You have played $PLAYED games, and your best game took $BEST guesses."
fi
SECRET=$(( RANDOM % 1000 + 1 ))
TRIES=0
echo 'Guess the secret number between 1 and 1000:'
while IFS= read -r GUESS; do
  ((TRIES++))
  if [[ ! $GUESS =~ ^[0-9]+$ ]]; then
    echo 'That is not an integer, guess again:'
  elif (( 10#$GUESS > SECRET )); then
    echo "It's lower than that, guess again:"
  elif (( 10#$GUESS < SECRET )); then
    echo "It's higher than that, guess again:"
  else
    $PSQL "INSERT INTO games(user_id, guesses) VALUES ($USER_ID, $TRIES)" > /dev/null
    echo "You guessed it in $TRIES tries. The secret number was $SECRET. Nice job!"
    break
  fi
done
