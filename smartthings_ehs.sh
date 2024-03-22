#!/bin/bash

platformUrl="https://api.smartthings.com/v1"
bearerToken="$1"
deviceId="$2"
name="smartthings_ehs"
configFile=/etc/smartthings.conf
labels=(power powerEnergy energy deltaEnergy waterTemp waterTempSet heatingTemp HeatingTempSet)

fail() {
  echo 2 $name "-" "$2"
  exit "$1"
}
getDeviceStatus() {
  curl -s --location "$platformUrl/devices/$deviceId/status" \
    --header 'Content-Type: application/json' \
    --header "Authorization: Bearer $bearerToken" \
    --header 'Accept: application/vnd.smartthings+json;v=1' |
    jq " \
 .components.main.powerConsumptionReport.powerConsumption.value.power, \
 .components.main.powerConsumptionReport.powerConsumption.value.powerEnergy, \
 .components.main.powerConsumptionReport.powerConsumption.value.energy, \
 .components.main.powerConsumptionReport.powerConsumption.value.deltaEnergy, \
 .components.main.temperatureMeasurement.temperature.value, \
 .components.main.thermostatCoolingSetpoint.coolingSetpoint.value, \
 .components.INDOOR.temperatureMeasurement.temperature.value, \
 .components.INDOOR.thermostatCoolingSetpoint.coolingSetpoint.value \
 "
}

if [ "$deviceId" == "" ]; then
  if test -f "$configFile"; then
    # shellcheck disable=SC1090
    . $configFile
  else
    if test -f ~/"$configFile"; then
      # shellcheck disable=SC1090
      . ~/"$configFile"
    else
      fail 2 "USAGE: $0 \$bearerToken \$deviceId or use configFile $configFile"
    fi
  fi
fi

ret="$(getDeviceStatus)"
exitCode="$?"

if [ "$exitCode" != "0" ]; then
  fail $exitCode
fi

retValue=""
cnt=0
while IFS= read -r value; do
  if [ "$retValue" == "" ]; then
    retValue="${labels[$cnt]}=$value"
  else
    retValue="$retValue|${labels[$cnt]}=$value"
  fi
  cnt=$((cnt + 1))
done <<<"$ret"

echo $exitCode $name "$retValue" A service with $cnt graphs
