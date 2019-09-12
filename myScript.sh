#!/usr/bin/env bash

KEY="fe68ed4bfeaf4759ac05255e03be4fa3"
FINDBYINGURL="https://api.spoonacular.com/recipes/findByIngredients"
FINDRECIPEURL=""
PARAMS=""
usage="$(basename "$0") [-m max] [-v] [-e] [-i] ingredient1
      ingredient2 ingredient3...ingredientN |
      run with --help or -h for more help."
HELP="This program is used to fetch a recipe from spoonacular given the ingredients you have at the moment.

      -v              specify only vegetarian recipes
      -e              specify only vegan recipes
      -m              specify max results
      -i              include recipes that require more ingredients than the
                      ones specified already"

#default optional argument values
VEGETARIAN=false
VEGAN=false
INCLUDE=false
declare -i MAX=10

#declare ingredient array
declare -a ING_ARRAY


parse_input() {
  if [[ "$2" == "-"* ]]; then
    echo "Expected argument not parameter."
    exit 1
  fi

  case "$1" in
    "max")
      MAX="$2"
    ;;
    "ingredient")
      ING_ARRAY+="$2"
    ;;
  esac
}

show_help() {
  echo "$HELP"
  echo "$usage"
}

search_spoonacular() {
  BUILTURL=""
  #default settings
  if [[ "$VEGETARIAN" = false && "$VEGAN" = false ]]; then
      BUILTURL+="$FINDBYINGURL?apiKey=$KEY&ingredients="
      for ing in "${ING_ARRAY[@]}"; do
        BUILTURL+="${ING_ARRAY[$ing]},"
      done

      if [[ "$BUILTURL" == *, ]]; then
        BUILTURL=${BUILTURL%?}
      fi
      echo "$BUILTURL"
      #curl --request GET "$BUILTURL"
  fi
}

#parse arguments

#show usage if no arguments given
if [ "$#" == "0" ]; then
  echo "$usage"
  exit 1
fi

#parse optional arguments
while [[ "$#" > 0 ]]; do
  case "$1" in
    #handle help
    -h | --help)
      show_help
      break
    ;;
    #handle max parameter
    -m | --max)
      parse_input "max" $2
      shift 2
    ;;
    #handle vegetarian argument
    -v | --vegetarian)
      if [[ "$VEGAN" = true ]]; then
        echo "Cannot be both vegan and vegetarian. Selecting vegetarian."
      fi
      VEGAN=false
      VEGETARIAN=true
      shift 1
    ;;
    #handle vegan argument
    -e | --e)
      if [[ "$VEGAN" = true ]]; then
        echo "Cannot be both vegan and vegetarian. Selecting vegan."
      fi
      VEGETARIAN=false
      VEGAN=true
      shift 1
    ;;
    #handle include argument
    -i | --include)
      INCLUDE=true
      shift
    ;;
    #handle incorrect optional arguments
    -*)
      show_help
      break
    ;;
    #handle ingredients
    *)
      parse_input "ingredient" "$1"
      shift
    ;;
  esac
done

search_spoonacular

exit 0
