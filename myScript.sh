#!/usr/bin/env bash

KEY="fe68ed4bfeaf4759ac05255e03be4fa3"
FINDBYINGURL="https://api.spoonacular.com/recipes/findByIngredients"
FINDRECIPEURL="https://api.spoonacular.com/recipes/"
usage="$(basename "$0") [-m max] [-v] [-e] [-i] ingredient1
      ingredient2 ingredient3...ingredientN |
      run with --help or -h for more help."
HELP="This program is used to fetch a recipe from spoonacular given the ingredients you have at the moment.

      -v              specify only vegetarian recipes
      -e              specify only vegan recipes
      -m              specify max results"

#default optional argument values
VEGETARIAN=false
VEGAN=false
declare -i MAX=10
declare DATA=""
declare -A RECIPELIST
declare RECIPEDATA=""

#declare ingredient array
declare -a ING_ARRAY


parse_input() {
  if [[ "$2" == "-"* ]]; then
    echo "Expected argument not parameter."
    exit 1
  fi

  case "$1" in
    "max")
    if [[ $MAX -gt 20 ]]; then
      echo "Max results is 20!"
      MAX="20"
    else
      MAX="$2"
    fi
    ;;
    "ingredient")
      ING_ARRAY+=("$2")
      #echo "added $2"
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
        BUILTURL+="$ing,"
      done

      #remove trailing comma
      if [[ "$BUILTURL" == *, ]]; then
        BUILTURL=${BUILTURL%?}
      fi

      #add number key
      BUILTURL+="&number=$MAX"

      #fetch data from server
      echo "Fetching recipes from Spoonacular"
      DATA=$(curl --request GET "$BUILTURL")
  fi
}

get_recipe() {
  #Build get request url for specific recipe
  BUILDURL=""
  BUILDURL+="$FINDRECIPEURL$1/information?apiKey=$KEY&includeNutrition=false"
  #echo $BUILDURL
  #send request
  RECIPEDATA=$(curl --request GET "$BUILDURL")
}

parse_results() {
  LIST="$(echo $DATA | jq -c -r ".[] | {id: .id, name: .title}")"
  while read -r line; do
    #echo "$line"
    ID="$(echo $line | jq -r '.id')"
    RECIPELIST[$ID]+="$(echo $line | jq -r '.name')"
  done <<< "$LIST"
}

show_recipe() {
  echo "Recipe Name: $(echo $RECIPEDATA | jq -r '.title')"
  echo "Ingredients:"
  echo "$(echo $RECIPEDATA | jq -c -r '.extendedIngredients[] | .original')"
  echo "Directions: "
  echo "$(echo $RECIPEDATA | jq -c -r '.instructions')"
}

show_results() {
  declare -i count=0
  echo "Results:"
  #show recipe names and index
  for recipe in "${!RECIPELIST[@]}"; do
    count+=1
    echo "[$count]${RECIPELIST[$recipe]}"
  done

  #ask for input
  echo "Please select a recipe by index to fetch more info about that recipe: "
  read index

  #check for valid input
  if [[ $index -gt ${#RECIPELIST[@]} || $index -le 0 ]]; then
    echo "Invalid Index: $index"
    exit 1
  fi

  #find recipe id
  declare -i ind_count
  for recipe in "${!RECIPELIST[@]}"; do
    ind_count+=1
    if [[ $ind_count -eq $index ]]; then
      get_recipe $recipe
      break
    fi
  done
}


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
parse_results
show_results
show_recipe

# for recipe in "${!RECIPELIST[@]}"; do
#   echo "${RECIPELIST[$recipe]} and $recipe"
# done

exit 0
