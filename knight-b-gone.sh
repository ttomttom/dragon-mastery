#!/bin/sh

#set -x

# maximum number of stat points that
# can be handed out to a dragon
STAT_MAX=10

# a stat buff that is applied to the
# dragons' highest stat
STAT_BUFF=2

# stat diminishing counter used to 
# keep track of how many stas we deminished
STAT_DIM=0

# highest stat of the knight
HIGH_STAT=-1

# number of fights to fight
ITERATIONS=100
COUNTER=0

# success counter
SUCCESS=0

BATTLE_LOG=battle.log

# quick and dirty hack to return the value of a JSON object
# don't do this at home kinds, m'kay?
get_json_val() {

   #echo $1 | grep -o "\"name\":\"\?.[^\",}]*\"\?" | cut -d ':' -f2
   echo $1 | sed "s/.*\"$2\":\"\?\(.[^\",}]*\).*/\1/"
}

# compute dragon stat based on a knight stat. The ovarall strategy 
# is to match the knight stats but buff the highest knight stat 
# with +2, and diminish 1 from two other stats to keep the count 20.
get_stat() {
  local k_stat d_stat bufferd_stat

  # original knights' stat
  k_stat=$1

  # see if this is the knights' highest stat
  if [ ${HIGH_STAT} -eq ${k_stat} ]; then

    # buff the current stat
    bufferd_stat=`expr ${HIGH_STAT} + ${STAT_BUFF}`

    # see if it passes the maximum
    if [ ${bufferd_stat} -gt ${STAT_MAX} ]; then
      d_stat=${STAT_MAX}
    else
      d_stat=${bufferd_stat}
      # reset high stat so we don't buff it again in case the 
      # knight has more than one values with the highest stat
      HIGH_STAT=-1
    fi

  else 

    # mirror original stat
    if [ ${STAT_DIM} -eq ${STAT_BUFF} -o ${k_stat} -eq 0 ]; then
      # mirror original stat as is
      d_stat=${k_stat}
    else
      # diminish 1 from the original stat. this is needed to make
      # up for the buff we applied above
      d_stat=`expr ${k_stat} - 1`
      STAT_DIM=`expr ${STAT_DIM} + 1`
    fi

  fi

  return ${d_stat}
}

#MAIN

while [ ${COUNTER} -lt ${ITERATIONS} ]  ; do

  # a wild knight appears...
  WILD_KNIGHT="`curl -s http://www.dragonsofmugloar.com/api/game`"

  GAME=$(get_json_val "${WILD_KNIGHT}" "gameId")
  KNIGHT_NAME=$(get_json_val "${WILD_KNIGHT}" "name") 

  ATTACK=$(get_json_val "${WILD_KNIGHT}" "attack")
  ARMOR=$(get_json_val "${WILD_KNIGHT}" "armor")
  AGILITY=$(get_json_val "${WILD_KNIGHT}" "agility")
  ENDURANCE=$(get_json_val "${WILD_KNIGHT}" "endurance")

  # fetch weather
  WEATHER_RAW="`curl -s http://www.dragonsofmugloar.com/weather/api/report/${GAME}`" 
  WEATHER=`echo ${WEATHER_RAW} | xmlstarlet sel -t -v 'report/code'`

  if [ "${WEATHER}" = "T E" ]; then
 
    # achieve harmony 

    SCALES=5
    CLAWS=5
    WINGS=5
    FIRE=5

  elif [ "${WEATHER}" = "HVA" ]; then

    # sharpen claws and forget fire

    SCALES=5
    CLAWS=10
    WINGS=5
    FIRE=0
  else
  
    # get highest knight stat
    HIGH_STAT=0
    for s in ${ATTACK} ${ARMOR} ${AGILITY} ${ENDURANCE} ; do
      if [ $s -gt ${HIGH_STAT} ]; then
        HIGH_STAT=$s
      fi
    done

    # reset stat diminisher
    STAT_DIM=0

    # get dragon stats
    get_stat ${ATTACK} ; SCALES=$?
    get_stat ${ARMOR} ; CLAWS=$?
    get_stat ${AGILITY} ; WINGS=$?
    get_stat ${ENDURANCE} ; FIRE=$?

  fi

  # build dragon and send to fight
  DRAGON="{\"dragon\":{\"scaleThickness\":$SCALES,\"clawSharpness\":$CLAWS,\"wingStrength\":$WINGS,\"fireBreath\":$FIRE}}"
  FIGHT=`curl -s -H "Content-Type: application/json" -X PUT -d "${DRAGON}"  http://www.dragonsofmugloar.com/api/game/${GAME}/solution`
  #echo "${FIGHT}" | json_pp

  # see if dragon came back alive
  STATUS=$(get_json_val "${FIGHT}" "status")
  MESSAGE=$(get_json_val "${FIGHT}" "message")
  
  # count fortune
  if [ "${STATUS}" = "Victory" ]; then
    SUCCESS=`expr ${SUCCESS} + 1`
  fi

  # count iterations
  COUNTER=`expr ${COUNTER} + 1`

  # generate dragon name
  DRAGON_NAME=`rhino -f https://www.michaelfogleman.com/static/js/words.js dragon_generator.js`

  # log epic fight
  printf '\n\n ============================================++============================================\n' >> ${BATTLE_LOG}
  printf '| %40.40s   VS   %-40.40s |\n' "${KNIGHT_NAME}" "${DRAGON_NAME}"                                   >> ${BATTLE_LOG}
  printf '|------------------------------------------------------------------------------------------|\n'    >> ${BATTLE_LOG}
  printf '| WEATHER %80.80s |\n' "(${WEATHER})"                                                              >> ${BATTLE_LOG}
  printf '|------------------------------------------------------------------------------------------|\n'    >> ${BATTLE_LOG}
  printf '|%20.20s | %-20.1d || %20.20s | %-20.1d|\n' "ATTACK" ${ATTACK} "SCALE THICKNESS" ${SCALES}         >> ${BATTLE_LOG}
  printf '|%20.20s | %-20.1d || %20.20s | %-20.1d|\n' "ARMOR" ${ARMOR} "CLAW SHARPNESS" ${CLAWS}             >> ${BATTLE_LOG}
  printf '|%20.20s | %-20.1d || %20.20s | %-20.1d|\n' "AGILITY" ${AGILITY} "WING STRENGHT" ${WINGS}          >> ${BATTLE_LOG}
  printf '|%20.20s | %-20.1d || %20.20s | %-20.1d|\n' "ENDURANCE" ${ENDURANCE} "FIRE BREATH" ${FIRE}         >> ${BATTLE_LOG}
  printf '|------------------------------------------------------------------------------------------|\n'    >> ${BATTLE_LOG}
  printf '| %-88.88s |\n' "${STATUS} : ${MESSAGE}"                                                           >> ${BATTLE_LOG}
  printf ' ============================================++============================================\n'     >> ${BATTLE_LOG}

done

# get success ratio
echo "Success rate: ${SUCCESS}/${ITERATIONS}  ( $((100*${SUCCESS}/${ITERATIONS}))% ) "
