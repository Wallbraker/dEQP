// Copyright 2018, Collabora Inc.
// SPDX-License-Identifier: BSL-1.0
/*!
 * Contains the code for parsing args.
 */
module deqp.config.args;

import watt = [
	watt.text.getopt,
	];

import deqp.io;
import deqp.driver;
import deqp.config.info;


fn parseArgs(settings: Settings, args: string[])
{
	printFailing, noRerunTests, noPassedResults: bool;
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
	watt.getopt(ref args, "print-failing", ref printFailing);
	watt.getopt(ref args, "randomize", ref randomize);
	watt.getopt(ref args, "check|regression-file", ref regressionFiles);


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
	if (printFailing) {
		settings.printFailing = printFailing;
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

	if (args.length > 1) {
		info("Unknown argument '%s'", args[1]);
		printAllArgsAndConfig();
		abort(" :: Exiting!");
	}
}
