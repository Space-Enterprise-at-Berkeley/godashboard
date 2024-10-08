# Installation Instructions
Note: These are temporary instructions that will be updated when things are more complete. This process will be simpler in the future.
* Clone this repository.
* Download Godot from [https://godotengine.org/](https://godotengine.org/). It's a single portable executable, so it should be simple to run.
* Run Godot and click on the import button in the top right. Navigate to the `project.godot` file in the root of this repository and import it.
* To run the dashboard, click the **Run Project** button in the top right of the editor, or press `F5`.
* **Mac only:** Go into the `scripts` folder in the Godashboard reposity and run `python3 multicast_forwarder.py 1XX`, where `1XX` is your reserved IP. For example, if you are `10.0.0.199`, `1XX` would be `199`. **This script must be running for incoming comms to work on Mac. (Run it every time)**
* To kill it if it doesn't close properly, either go back to the editor and click the **Stop Running Project** button or press `F8`.
* Ask Zander if anything goes wrong.