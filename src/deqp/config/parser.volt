// Copyright 2018, Collabora Inc.
// SPDX-License-Identifier: BSL-1.0
/*!
 * This file holds code for reading the configuration file.
 */
module deqp.config.parser;

import watt = [watt.io.file, watt.xdg.basedir];
import toml = watt.toml;

import deqp.io;
import deqp.driver;


enum ConfigFile = "dEQP/config.toml";

fn parseConfigFile(s: Settings)
{
	version (Linux) {
		configFile := watt.findConfigFile(ConfigFile);
	} else {
		configFile: string[];
	}
		
	if (configFile is null) {
		return;
	}

	root := toml.parse(cast(string) watt.read(configFile[0]));
	if (root.type != toml.Value.Type.Table) {
		return;
	}

	if (root.hasKey("ctsBuildDir")) {
		s.ctsBuildDir = root["ctsBuildDir"].str();
	}
	if (root.hasKey("testNamesFile")) {
		s.testNamesFiles = [root["testNamesFile"].str()];
	}
	if (root.hasKey("resultsFile")) {
		s.resultsFile = root["resultsFile"].str();
	}
	if (root.hasKey("hastyBatchSize")) {
		s.batchSize = cast(u32) root["hastyBatchSize"].integer();
	}
	if (root.hasKey("batchSize")) {
		s.batchSize = cast(u32) root["batchSize"].integer();
	}
	if (root.hasKey("tempDir")) {
		s.tempDir = root["tempDir"].str();
	}
	if (root.hasKey("threads")) {
		s.threads = cast(u32) root["threads"].integer();
	}
	if (root.hasKey("noRerunTests")) {
		s.noRerunTests = root["noRerunTests"].boolean();
	}
	if (root.hasKey("noPassedResults")) {
		s.noRerunTests = root["noPassedResults"].boolean();
	}
	if (root.hasKey("regressionFile")) {
		s.resultsFile = root["regressionFile"].str();
	}

	if (root.hasKey("printFailing")) {
		v := root["printFailing"].boolean();
		s.printOpts.fail = true;
		s.printOpts.quality = true;
		s.printOpts.regression = true;
	}

	if (root.hasKey("printFail")) {
		s.printOpts.fail = root["printFail"].boolean();
	}
	if (root.hasKey("printQuality")) {
		s.printOpts.quality = root["printQuality"].boolean();
	}
	if (root.hasKey("printRegression")) {
		s.printOpts.regression = root["printRegression"].boolean();
	}

	if (root.hasKey("colourTerm")) {
		s.printOpts.colour = root["colourTerm"].boolean();
	}

	if (root.hasKey("groupUpdates")) {
		s.printOpts.groups = root["groupUpdates"].boolean();
	}

	setIfFound(root, "deqpSurfaceType", ref s.deqpSurfaceType);
	setIfFound(root, "deqpLogImages", ref s.deqpLogImages);
	setIfFound(root, "deqpWatchdog", ref s.deqpWatchdog);
	setIfFound(root, "deqpVisibility", ref s.deqpVisibility);
	setIfFound(root, "deqpConfig", ref s.deqpConfig);
	setIfFound(root, "deqpSurfaceWidth", ref s.deqpSurfaceWidth);
	setIfFound(root, "deqpSurfaceHeight", ref s.deqpSurfaceHeight);
}


private:

fn setIfFound(root: toml.Value, key: string, ref val: string)
{
	if (root.hasKey(key)) {
		val = root[key].str();
	}
}
