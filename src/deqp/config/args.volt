// Copyright 2018, Collabora Inc.
// SPDX-License-Identifier: BSL-1.0
/*!
 * Contains the code for parsing args.
 */
module deqp.config.args;

import watt = [
	watt.text.getopt,
	];

import watt.text.string : startsWith;

import deqp.io;
import deqp.driver;
import deqp.config.info;


fn parseArgs(settings: Settings, args: string[])
{
	printFailures, noRerunTests, noPassedResults, invokeWithGDB: bool;
	threads, batchSize, randomize: i32;
	ctsBuildDir, resultsFile, tempDir, regressionFile: string;
	testNamesFiles, regressionFiles: string[];

	watt.getopt(ref args, "threads", ref threads);
	watt.getopt(ref args, "batch-size|hasty-batch-size", ref batchSize);
	watt.getopt(ref args, "cts-build-dir", ref ctsBuildDir);
	watt.getopt(ref args, "test-names-file", ref testNamesFiles);
	watt.getopt(ref args, "results-file", ref resultsFile);
	watt.getopt(ref args, "temp-dir", ref tempDir);
	watt.getopt(ref args, "no-rerun-tests", ref noRerunTests);
	watt.getopt(ref args, "no-passed-results", ref noPassedResults);
	watt.getopt(ref args, "randomize", ref randomize);
	watt.getopt(ref args, "check|regression-file", ref regressionFiles);
	watt.getopt(ref args, "invoke-with-gdb", ref invokeWithGDB);
	watt.getopt(ref args, "print-failures", ref printFailures);

	printFail, noPrintFail, printRegression, noPrintRegression,
	printQuality, noPrintQuality, colourTerm, noColourTerm, groupUpdates, noGroupUpdates: bool;

	watt.getopt(ref args, "print-fail", ref printFail);
	watt.getopt(ref args, "no-print-fail", ref noPrintFail);
	watt.getopt(ref args, "print-regression", ref printRegression);
	watt.getopt(ref args, "no-print-regression", ref noPrintRegression);
	watt.getopt(ref args, "print-quality", ref printQuality);
	watt.getopt(ref args, "no-print-quality", ref noPrintQuality);

	watt.getopt(ref args, "colour-term", ref colourTerm);
	watt.getopt(ref args, "no-colour-term", ref noColourTerm);

	watt.getopt(ref args, "group-updates", ref groupUpdates);
	watt.getopt(ref args, "no-group-updates", ref noGroupUpdates);


	if (threads > 0) {
		settings.threads = cast(u32) threads;
	}
	if (batchSize > 0) {
		settings.batchSize = cast(u32) batchSize;
	}
	if (randomize > 0) {
		settings.randomize = cast(u32) randomize;
	}
	if (ctsBuildDir !is null) {
		settings.ctsBuildDir = ctsBuildDir;
	}
	if (testNamesFiles !is null) {
		settings.testNamesFiles = testNamesFiles;
	}
	if (resultsFile !is null) {
		settings.resultsFile = resultsFile;
	}
	if (tempDir !is null) {
		settings.tempDir = tempDir;
	}
	if (noRerunTests) {
		settings.noRerunTests = noRerunTests;
	}
	if (noPassedResults) {
		settings.noPassedResults = noPassedResults;
	}
	if (regressionFiles !is null) {
		settings.regressionFiles = regressionFiles;
	}
	if (invokeWithGDB) {
		settings.invokeWithGDB = invokeWithGDB;
	}
	if (printFailures) {
		settings.printOpts.regression = true;
		settings.printOpts.quality = true;
		settings.printOpts.fail = true;
		info("\t--print-failures is deprecated instead use:");
		info("\t--[no-]print-fail --[no-]print-regression --[no-]print-quality");
	}

	if (printFail && noPrintFail) {
		info("\tConflicting arguments for printFail");
		abort(" :: Exiting!");
	} else if (printFail) {
		settings.printOpts.fail = true;
	} else if (noPrintFail) {
		settings.printOpts.fail = false;
	}

	if (printQuality && noPrintQuality) {
		info("\tConflicting arguments for printQuality");
		abort(" :: Exiting!");
	} else if (printQuality) {
		settings.printOpts.quality = true;
	} else if (noPrintQuality) {
		settings.printOpts.quality = false;
	}

	if (printRegression && noPrintRegression) {
		info("\tConflicting arguments for printRegression");
		abort(" :: Exiting!");
	} else if (printRegression) {
		settings.printOpts.regression = true;
	} else if (noPrintRegression) {
		settings.printOpts.regression = false;
	}

	if (colourTerm && noColourTerm) {
		info("\tConflicting arguments for colourTerm");
		abort(" :: Exiting!");
	} else if (colourTerm) {
		settings.printOpts.colour = true;
	} else if (noColourTerm) {
		settings.printOpts.colour = false;
	}

	if (groupUpdates && noGroupUpdates) {
		info("\tConflicting arguments for groupUpdates");
		abort(" :: Exiting!");
	} else if (groupUpdates) {
		settings.printOpts.groups = true;
	} else if (noGroupUpdates) {
		settings.printOpts.groups = false;
	}

	setIfFound(ref args, "deqp-surface-type", ref settings.deqpSurfaceType);
	setIfFound(ref args, "deqp-log-images", ref settings.deqpLogImages);
	setIfFound(ref args, "deqp-watchdog", ref settings.deqpWatchdog);
	setIfFound(ref args, "deqp-visibility", ref settings.deqpVisibility);
	setIfFound(ref args, "deqp-gl-config-name", ref settings.deqpConfig);
	setIfFound(ref args, "deqp-surface-width", ref settings.deqpSurfaceWidth);
	setIfFound(ref args, "deqp-surface-height", ref settings.deqpSurfaceHeight);

	bad := false;
	foreach (arg; args[1 .. $]) {
		if (arg.startsWith("--deqp")) {
			settings.deqpExtraArgs ~= arg;
		} else {
			info("Unknown argument '%s'", arg);
			bad = true;
		}
	}

	if (bad) {
		printAllArgsAndConfig();
		abort(" :: Exiting!");
	}
}


private:

fn setIfFound(ref args: string[], arg: string, ref val: string)
{
	string tmp;
	if (watt.getopt(ref args, arg, ref tmp)) {
		val = tmp;
	}
}

fn setIfFound(ref args: string[], arg: string, ref val: bool)
{
	tmp: bool;
	if (watt.getopt(ref args, arg, ref tmp)) {
		val = tmp;
	}
}
