// Copyright 2018, Collabora Inc.
// SPDX-License-Identifier: BSL-1.0
/*!
 * Contains code and classes for running tests and reading back results.
 */
module deqp.tests.runner;

import watt = [
	watt.path,
	watt.io.file,
	watt.io.streams,
	watt.io.monotonic,
	watt.algorithm,
	watt.text.sink,
	watt.text.string,
	watt.text.format,
	watt.math.random,
	];

import watt.path : sep = dirSeparator;

import file = watt.io.file;

import deqp.io;
import deqp.sinks;
import deqp.driver;
import deqp.launcher;

import deqp.tests.test;
import deqp.tests.info;
import deqp.tests.result;
import deqp.tests.parser;


fn dispatch(drv: Driver, suites: Suite[], ref opts: PrintOptions)
{
	s := new Scheduler(drv, suites, ref opts);

	foreach (suite; suites) {
		// Temporary directory.
		watt.mkdirP(suite.tempDir);

		// Set the correct working directory for running tests.
		file.chdir(suite.runDir);

		// Create a secheduling struct for the current suite.
		current: Current;
		current.setup(s, suite);


		if (drv.settings.randomize != 0) {
			current.runRandom();
		} else if (drv.settings.batchSize != 0) {
			current.runRest(drv.settings.batchSize);
		} else if (suite.suffix == "2") {
			current.runSingle("dEQP-GLES2.functional.flush_finish.wait");
			current.runStartsWith("dEQP-GLES2.functional.vertex_arrays.multiple_attributes");
			current.runRest();
		} else if (suite.suffix == "3") {
			// Run as separate tests.
			current.runStartsWith("dEQP-GLES3.functional.flush_finish", 1);
			current.runStartsWith("dEQP-GLES3.functional.shaders.builtin_functions.precision", 8);
			current.runStartsWith("dEQP-GLES3.functional.vertex_arrays.multiple_attributes", 8);
			current.runStartsWith("dEQP-GLES3.functional.vertex_arrays.single_attribute", 8);
			current.runStartsWith("dEQP-GLES3.functional.rasterization", 16);
			current.runRest();
		} else if (suite.suffix == "31") {
			current.runStartsWith("dEQP-GLES31.functional.shaders.builtin_functions.precision.refract", 1);
			current.runStartsWith("dEQP-GLES31.functional.shaders.builtin_functions.precision.faceforward", 1);
			current.runStartsWith("dEQP-GLES31.functional.shaders.builtin_functions.precision", 8);
			current.runStartsWith("dEQP-GLES31.functional.copy_image.compressed.viewclass", 8);
			current.runRest();
		} else {
			current.runRest();
		}
	}

	info("\tWaiting for test batchs to complete.");

	// Wait for all test groups to complete.
	drv.launcher.waitAll();
}

/*!
 * A group of tests to be given to the testsuit.
 */
class Group
{
public:
	drv: Driver;
	opts: PrintOptions;
	suite: Suite;
	start, end: u32;

	filePrefix: string;
	fileCtsLog: string;
	fileConsole: string;
	fileTests: string;
	tests: Test[];

	timeStart, timeStop: i64;

	//! Return value from runner.
	retval: i32;


public:
	this(drv: Driver, suite: Suite, tests: Test[], offset: u32, filePrefix: string, ref opts: PrintOptions)
	{
		this.drv = drv;
		this.opts = opts;
		this.suite = suite;
		this.tests = tests;
		this.start = offset + 1;
		this.end = offset + cast(u32) tests.length;
		this.filePrefix = filePrefix;
		this.fileTests = new "${suite.tempDir}${sep}${filePrefix}_${start}.tests";
		this.fileCtsLog = new "${suite.tempDir}${sep}${filePrefix}_${start}.log";
		this.fileConsole = new "${suite.tempDir}${sep}${filePrefix}_${start}.console";

		drv.removeOnExit(fileTests);
		drv.removeOnExit(fileCtsLog);
		drv.removeOnExit(fileConsole);
	}

	fn run(launcher: Launcher)
	{
		s := drv.settings;

		cmd := suite.command;
		args := [
			"--deqp-stdin-caselist",
			new "--deqp-surface-type=${s.deqpSurfaceType}",
			new "--deqp-log-images=${s.deqpLogImages}",
			new "--deqp-watchdog=${s.deqpWatchdog}",
			new "--deqp-visibility=${s.deqpVisibility}",
			new "--deqp-gl-config-name=${s.deqpConfig}",
			new "--deqp-surface-width=${s.deqpSurfaceWidth}",
			new "--deqp-surface-height=${s.deqpSurfaceHeight}",
			new "--deqp-log-filename=${fileCtsLog}",
		] ~ s.deqpExtraArgs;

		if (s.invokeWithGDB) {
			args = ["-batch", "-return-child-result",
				"-ex", "run",
				"-ex", "bt",
				"-ex", "stop",
				"-ex", "q",
				"--args", cmd] ~ args;
			cmd = "gdb";
		}

		console := new watt.OutputFileStream(fileConsole);

		ss: watt.StringSink;
		foreach (test; tests) {
			ss.sink(test.name);
			ss.sink("\n");
		}

		timeStart = watt.ticks();

		launcher.run(suite.command, args, ss.toString(), console, done);
		console.close();
	}


	fn writeTestsToFile()
	{
		f := new watt.OutputFileStream(fileTests);
		foreach (t; tests) {
			f.write(t.name);
			f.write("\n");
		}
		f.flush();
		f.close();
	}

private:
	fn done(retval: i32)
	{
		// Save the retval, for tracking BadTerminate status.
		this.retval = retval;

		readResults();

		// Time keeping.
		timeStop = watt.ticks();
		ms := watt.convClockFreq(timeStop - timeStart, watt.ticksPerSecond, 1000);
		time := watt.format(" (%s.%03ss)", ms / 1000, ms % 1000);

		hasFailedTests: bool;
		foreach (test; tests) {
			hasFailedTests |= test.hasFailed();
		}

		printResultFromGroup(ref opts, suite, tests,
		                     retval, hasFailedTests,
		                     start, end, time);

		// If the test run didn't complete.
		if (retval != 0 || hasFailedTests) {
			// Write out the tests to a file, for debugging.
			writeTestsToFile();

			// Preserve some files so the user can investigate.
			drv.preserveOnExit(fileConsole);
			drv.preserveOnExit(fileCtsLog);
			drv.preserveOnExit(fileTests);
		}
	}

	fn readResults()
	{
		parseResultsAndAssign(fileConsole, tests);

		// If the testsuit terminated cleanely nothing more to do.
		if (retval == 0) {
			return;
		}

		// Loop over and set tests to BadTerminate(Pass).
		foreach (test; tests) {
			if (test.result != Result.Pass) {
				test.result = Result.BadTerminate;
			} else {
				test.result = Result.BadTerminatePass;
			}
		}
	}
}

struct GroupSink = mixin SinkStruct!Group;


private:

/*!
 * Schedules tests in a slightly more optimized way.
 */
final class Scheduler
{
public:
	drv: Driver;
	launcher: Launcher;
	opts: PrintOptions;

	numDispatched: size_t;
	numTests: size_t;

	gs: GroupSink;


public:
	enum MinBatchSize = Step4Size;

	enum Step1Left = 8192u;
	enum Step1Size = 64u;
	enum Step2Left = 4096u;
	enum Step2Size = 32u;
	enum Step3Left = 512u;
	enum Step3Size = 16u;
	enum Step4Size = 4u;


public:
	this(drv: Driver, suites: Suite[], ref opts: PrintOptions)
	{
		this.drv = drv;
		this.launcher = drv.launcher;
		this.opts = opts;

		foreach (suite; suites) {
			numTests += suite.tests.length;
		}
	}

	fn calcBatchSize() size_t
	{
		left := numTests - numDispatched;

		if (left > Step1Left) {
			return Step1Size;
		} else if (left > Step2Left) {
			return Step2Size;
		} else if (left > Step3Left) {
			return Step3Size;
		} else if (left > Step4Size) {
			return Step4Size;
		} else {
			return left;
		}
	}

	fn launch(suite: Suite, tests: Test[], offset: u32)
	{
		group := new Group(drv, suite, tests, offset, "batch", ref opts);
		group.run(launcher);

		numDispatched += tests.length;
		gs.sink(group);
	}
}

/*!
 * Struct holding states for scheduling tests from a Suite.
 */
struct Current
{
public:
	store: size_t[string];
	tests: Test[];
	suite: Suite;
	offset: size_t;
	started: bool[];
	s: Scheduler;


public:
	fn setup(s: Scheduler, suite: Suite)
	{
		this.s = s;
		this.tests = suite.tests;
		this.suite = suite;
		this.offset = 0;
		this.started = new bool[](tests.length);

		foreach (i, test; suite.tests) {
			store[test.name] = i;
		}
	}

	fn runRandom()
	{
		tests = new Test[](tests);

		seed := s.drv.settings.randomize;

		r: watt.RandomGenerator;
		r.seed(seed);

		info("\tRandomizing tests using seed %s", seed);

		i: i32 = cast(i32) tests.length - 1;

		for (; i >= 0; i--) {

			index := r.uniformI32(0, i);

			old := tests[index];
			tests[index] = tests[i];
			tests[i] = old;
		}

		runRest(s.drv.settings.batchSize);
	}

	/*!
	 * Start a single test of the extact name.
	 */
	fn runSingle(test: string)
	{
		ptr := test in store;
		if (ptr is null) {
			return;
		}

		i := *ptr;
		if (started[i]) {
			return;
		}

		// Inform the user.
		info("\tScheduling test '%s'.", test);

		// Launch the test, no need to give batch size since
		// it is only one test anyways.
		batch(i, i + 1);
	}

	/*!
	 * Schedule tests starting with the given string,
	 * in smaller batches then normal.
	 */
	fn runStartsWith(str: string, batchSize: size_t = 4u)
	{
		// Skip to first matching test.
		offset = 0;
		skipStartedOrNotMatching(str);

		// Early out if we didn't find any tests.
		if (offset >= tests.length) {
			return;
		}

		// Inform the user.
		info("\tScheduling tests starting with '%s'.", str);

		while (offset < tests.length) {
			start := offset;
			skipNotStartedAndMatching(str);
			end := offset;

			if (start == end) {
				break;
			}

			batch(start, end, batchSize);

			skipStartedOrNotMatching(str);
		}
	}

	/*!
	 * Schedule all remaining tests.
	 */
	fn runRest(batchSize: size_t = 0u)
	{
		// Skip to first matching test.
		offset = 0;
		skipStarted();

		// Early out if we didn't find any tests.
		if (offset >= tests.length) {
			return;
		}

		// Inform the user.
		info("\tScheduling all remaining GLES%s tests.", suite.suffix);

		while (offset < tests.length) {
			start := offset;
			skipNotStarted();
			end := offset;
			if (start == end) {
				break;
			}

			batch(start, end, batchSize);

			skipStarted();
		}
	}


private:
	fn skipStarted()
	{
		while (offset < started.length && started[offset]) {
			offset++;
		}
	}

	fn skipNotStarted()
	{
		while (offset < started.length && !started[offset]) {
			offset++;
		}
	}

	fn skipStartedOrNotMatching(str: string)
	{
		while (offset < started.length && (started[offset] ||
		       !watt.startsWith(tests[offset].name, str))) {
			offset++;
		}
	}

	fn skipNotStartedAndMatching(str: string)
	{
		while (offset < started.length && !started[offset] &&
		       watt.startsWith(tests[offset].name, str)) {
			offset++;
		}
	}

	fn batch(i1: size_t, i2: size_t, batchSize: size_t = 0)
	{
		offset := i1;
		tests := this.tests[0 .. i2];

		while (offset < tests.length) {
			left := tests.length - offset;
			size := batchSize != 0 ? batchSize : s.calcBatchSize();
			size = watt.min(left, size);

			t := markAndReturn(offset, offset + size);

			s.launch(suite, t, cast(u32) offset);

			offset += size;
		}
	}

	fn markAndReturn(i1: size_t, i2: size_t) Test[]
	{
		foreach (i; i1 .. i2) {
			started[i] = true;
		}

		return tests[i1 .. i2];
	}
}
