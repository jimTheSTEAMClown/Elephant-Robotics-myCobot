#!/bin/bash
# rover_example_wget.sh
echo "getting rover designs and pin_config"
sleep 2
echo "Checking for ./hal directory..."
# Check if ./hal exists
if [ ! -d "./hal" ]; then
    echo "Creating ./hal"
    mkdir ./hal
else
    echo "./hal already exists"
fi

# Getting rover examples
echo ""
echo "Downloading rover files..."

wget -O rover_test.py https://raw.githubusercontent.com/jimTheSTEAMClown/Robots-Rovers-Project-Template/refs/heads/main/Raspberry/projects/simple-rover-test/rover_test.py
wget -O rover_keys.py https://raw.githubusercontent.com/jimTheSTEAMClown/Robots-Rovers-Project-Template/refs/heads/main/Raspberry/projects/rover-drive-examples/rover_keys.py
wget -O rover_distance.py https://raw.githubusercontent.com/jimTheSTEAMClown/Robots-Rovers-Project-Template/refs/heads/main/Raspberry/projects/rover-drive-examples/rover_distance.py
# Move into hal directory
cd ./hal || exit 1
wget -O __init__.py https://raw.githubusercontent.com/jimTheSTEAMClown/Robots-Rovers-Project-Template/refs/heads/main/Raspberry/projects/rover-drive-examples/hal/__init__.py
wget -O pin_config.py https://raw.githubusercontent.com/jimTheSTEAMClown/Robots-Rovers-Project-Template/refs/heads/main/Raspberry/projects/rover-drive-examples/hal/pin_config.py

echo ""
echo "Done."
ls -l
