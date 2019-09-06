// Copyright 2018, Collabora Inc.
// SPDX-License-Identifier: BSL-1.0
/*!
 * Contains code and classes for parsing dEQP tests.
 */
module deqp.tests.parser;

import watt = [
	watt.io.file,
	watt.text.string,
	];

import deqp.io;
import deqp.sinks;
import deqp.driver;

import deqp.tests.test;
import deqp.tests.result;


/*!
 * Parse the given tests file.
 */
fn parseTestFile(s: Settings)
{
	abortOnMissingTestsFile(s.testNamesFiles);
	lines: string[];

	info(" :: Gathering test names.");
	foreach (testNamesFile; s.testNamesFiles) {
		info("\tReading file %s.", testNamesFile);
		file := cast(string) watt.read(testNamesFile);
		lines ~= watt.splitLines(file);
	}

	gl3: StringsSink;
	gl31: StringsSink;
	gl32: StringsSink;
	gl33: StringsSink;
	gl4: StringsSink;
	gl41: StringsSink;
	gl42: StringsSink;
	gl43: StringsSink;
	gl44: StringsSink;
	gl45: StringsSink;
	gl46: StringsSink;
	gles2: StringsSink;
	gles3: StringsSink;
	gles31: StringsSink;

	info("\tOrganizing tests.");
	foreach (line; lines) {
		if (watt.startsWith(line, "dEQP-GLES2")) {
			gles2.sink(line);
		} else if (watt.startsWith(line, "dEQP-GLES31")) {
			gles31.sink(line);
		} else if (watt.startsWith(line, "dEQP-GLES3")) {
			gles3.sink(line);
		} else if (watt.startsWith(line, "KHR-GL30")) {
			gl3.sink(line);
		} else if (watt.startsWith(line, "KHR-GL31")) {
			gl31.sink(line);
		} else if (watt.startsWith(line, "KHR-GL32")) {
			gl32.sink(line);
		} else if (watt.startsWith(line, "KHR-GL33")) {
			gl33.sink(line);
		} else if (watt.startsWith(line, "KHR-GL40")) {
			gl4.sink(line);
		} else if (watt.startsWith(line, "KHR-GL41")) {
			gl41.sink(line);
		} else if (watt.startsWith(line, "KHR-GL42")) {
			gl42.sink(line);
		} else if (watt.startsWith(line, "KHR-GL43")) {
			gl43.sink(line);
		} else if (watt.startsWith(line, "KHR-GL44")) {
			gl44.sink(line);
		} else if (watt.startsWith(line, "KHR-GL45")) {
			gl45.sink(line);
		} else if (watt.startsWith(line, "KHR-GL46")) {
			gl46.sink(line);
		} else if (watt.startsWith(line, "#") || line.length == 0) {
			/* nop */
		} else {
			warn("Unknown tests '%s'", line);
		}
	}

	s.testsGL3 = gl3.toArray();
	s.testsGL31 = gl31.toArray();
	s.testsGL32 = gl32.toArray();
	s.testsGL33 = gl33.toArray();
	s.testsGL4 = gl4.toArray();
	s.testsGL41 = gl41.toArray();
	s.testsGL42 = gl42.toArray();
	s.testsGL43 = gl43.toArray();
	s.testsGL44 = gl44.toArray();
	s.testsGL45 = gl45.toArray();
	s.testsGL46 = gl46.toArray();
	s.testsGLES2 = gles2.toArray();
	s.testsGLES3 = gles3.toArray();
	s.testsGLES31 = gles31.toArray();

	info("\tGot %s tests.", s.testsGL3.length +
	                        s.testsGL31.length +
	                        s.testsGL32.length +
	                        s.testsGL33.length +
	                        s.testsGL4.length +
	                        s.testsGL41.length +
	                        s.testsGL42.length +
	                        s.testsGL43.length +
	                        s.testsGL44.length +
	                        s.testsGL45.length +
	                        s.testsGL46.length +
	                        s.testsGLES2.length +
	                        s.testsGLES3.length +
	                        s.testsGLES31.length);
}

fn parseAndCheckRegressions(suites: Suite[], filenames: string[]) i32
{
	abortOnMissingRegressionFile(filenames);

	info(" :: Checking for regressions.");

	// Build a searchable database.
	database: Test[string];
	foreach (suite; suites) {
		foreach (test; suite.tests) {
			test.compare = Result.NotListed;
			database[test.name] = test;
		}
	}

	foreach (filename; filenames) {
		// Load the file and split into lines.
		info("\tReading file %s.", filename);
		file := cast(string) watt.read(filename);
		lines := watt.splitLines(file);

		// Skip any json header.
		count: size_t;
		foreach (line; lines) {
			if (watt.startsWith(line, "dEQP-GLES")) {
				break;
			}
			if (watt.startsWith(line, "KHR-GL")) {
				break;
			}
			count++;
		}

		// Loop over all lines not including the JSON header.
		foreach (line; lines[count .. $]) {

			if (watt.startsWith(line, "KHR-GL30") ||
			    watt.startsWith(line, "KHR-GL31") ||
			    watt.startsWith(line, "KHR-GL32") ||
			    watt.startsWith(line, "KHR-GL33") ||
			    watt.startsWith(line, "KHR-GL40") ||
			    watt.startsWith(line, "KHR-GL41") ||
			    watt.startsWith(line, "KHR-GL42") ||
			    watt.startsWith(line, "KHR-GL43") ||
			    watt.startsWith(line, "KHR-GL44") ||
			    watt.startsWith(line, "KHR-GL45") ||
			    watt.startsWith(line, "KHR-GL46") ||
			    watt.startsWith(line, "dEQP-GLES2") ||
			    watt.startsWith(line, "dEQP-GLES31") ||
			    watt.startsWith(line, "dEQP-GLES3")) {
				/* nop */
			} else if (watt.startsWith(line, "#") || line.length == 0) {
				continue;
			} else {
				warn("Unknown tests '%s'", line);
				continue;
			}

			name, resultText: string;
			splitNameAndResult(line, out name, out resultText);
			t := name in database;
			if (t is null) {
				continue;
			}
			test := *t;

			test.compare = parseResult(resultText);
		}
	}

	regressed, improvement, quality, any: bool;
	foreach (suite; suites) {
		foreach (test; suite.tests) {
			// Update change tracking.
			improvement = improvement || test.hasImproved();
			regressed = regressed || test.hasRegressed();
			quality = quality || test.hasQualityChange();
			any = any || test.hasAnyChangeExceptNotListed();
		}
	}

	ret := 0;
	if (regressed) {
		info("\tRegression(s) found!");
		ret = 1;
	}

	if (improvement) {
		info("\tImprovement(s) found!");
		ret = 1;
	}

	if (quality) {
		info("\tQuality change(s) found.");
	}

	if (!improvement && !regressed && !quality) {
		if (any) {
			info("\tChange(s) found.");
			ret = 1;
		} else {
			info("\tNo change(s) found.");
		}
	}

	return ret;
}

fn parseResultsAndAssign(fileConsole: string, tests: Test[])
{
	console := cast(string) watt.read(fileConsole);

	state: ParseState;
	state.tests = tests;
	foreach (index, test; tests) {
		state.map[test.name] = cast(u32)index;
	}

	foreach (l; watt.splitLines(console)) {
		if (state.testCase.length == 0) {
			auto i = watt.indexOf(l, HeaderName);
			if (i < 0) {
				continue;
			} else {
				state.getTestCase(i, l);
			}
		} else {
			auto iName = watt.indexOf(l, HeaderName);
			auto iPass = watt.indexOf(l, HeaderPass);
			auto iFail = watt.indexOf(l, HeaderFail);
			auto iSupp = watt.indexOf(l, HeaderSupp);
			auto iQual = watt.indexOf(l, HeaderQual);
			auto iIErr = watt.indexOf(l, HeaderIErr);
			auto iComp = watt.indexOf(l, HeaderComp);

			if (iName >= 0) {
				//info("Name %s", testCase);
				state.setResult(Result.MalformedResult);
				state.getTestCase(iName, l);
			} else if (iPass >= 0) {
				//info("Pass %s", testCase);
				state.setResult(Result.Pass);
			} else if (iFail >= 0) {
				//auto res = l[iFail + startFail.length .. $ - 2].idup;
				state.setResult(Result.Fail);
			} else if (iSupp >= 0) {
				//info("!Sup %s", testCase);
				state.setResult(Result.NotSupported);
			} else if (iQual >= 0) {
				//info("Qual %s", testCase);
				state.setResult(Result.QualityWarning);
			} else if (iIErr >= 0) {
				//auto res = l[iIErr + startIErr.length .. $ - 2].idup;
				state.setResult(Result.InternalError);
			} else if (iComp >= 0) {
				//auto res = l[iComp + startComp.length .. $ - 2].idup;
				state.setResult(Result.CompatibilityWarning);
			}
		}
	}

	state.setResult(Result.MalformedResult);
}


private:

fn setResult(ref state: ParseState, r: Result)
{
	if (state.testCase.length == 0) {
		return;
	}

	state.tests[state.index].result = r;
	state.testCase = null;
}

fn getTestCase(ref state: ParseState, i: ptrdiff_t, l: string)
{
	if (l.length < HeaderName.length + 1) {
		warn("\t\tReally weird TestCase line! '%s'", l);
	}

	if (l.length < HeaderName.length + 4) {
		warn("\t\tWeird TestCase line! '%s'", l);
		return;
	}

	state.testCase = l[cast(size_t) i + HeaderName.length .. $ - 3];

	if (state.testCase in state.map is null) {
		warn("\t\tCould not find test '%s'?!", state.testCase);
		state.testCase = null;
		return;
	}

	state.index = state.map[state.testCase];
}



struct ParseState
{
	testCase: string;
	map: u32[string];
	tests: Test[];
	index: u32;
};

enum HeaderName = "Test case '";
enum HeaderIErr = "InternalError (";
enum HeaderPass = "Pass (";
enum HeaderFail = "Fail (";
enum HeaderSupp = "NotSupported (";
enum HeaderQual = "QualityWarning (";
enum HeaderComp = "CompatibilityWarning (";

fn splitNameAndResult(text: string, out name: string, out result: string) string
{
	foreach(i, dchar c; text) {
		if (watt.isWhite(c)) {
			name = text[0 .. i];
			text = text[i .. $];
			break;
		}
	}

	foreach (i, dchar c; text) {
		if (!watt.isWhite(c)) {
			text = text[i .. $];
			break;
		}
	}

	foreach (i, dchar c; text) {
		if (watt.isWhite(c)) {
			text = text[0 .. i];
			break;
		}
	}

	result = text[0 .. $];
	return text;
}

fn parseResult(text: string) Result
{
	switch (text) {
	case "Incomplete":           return Result.Incomplete;
	case "Fail":                 return Result.Fail;
	case "NotSupported":         return Result.NotSupported;
	case "InternalError":        return Result.InternalError;
	case "BadTerminate":         return Result.BadTerminate;
	case "BadTerminatePass":     return Result.BadTerminatePass;
	case "QualityWarning":       return Result.QualityWarning;
	case "CompatibilityWarning": return Result.CompatibilityWarning;
	case "Pass":                 return Result.Pass;
	default:                     return Result.Incomplete;
	}
}

fn abortOnMissingTestsFile(filenames: string[])
{
	foreach (filename; filenames) {
		if (!watt.exists(filename) || !watt.isFile(filename)) {
			abort(new "Test names file '${filename}' does not exists!");
		}
	}
}

fn abortOnMissingRegressionFile(filenames: string[])
{

	foreach (filename; filenames) {
		if (!watt.exists(filename) || !watt.isFile(filename)) {
			abort(new "Regression file '${filename}' does not exists!");
		}
	}
}
