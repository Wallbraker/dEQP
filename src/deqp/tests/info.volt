// Copyright 2018, Collabora Inc.
// SPDX-License-Identifier: BSL-1.0
/*!
 * Contains code to print out info lists.
 */
module deqp.tests.info;

import deqp.io;

import deqp.tests.test;
import deqp.tests.result;


struct PrintOptions
{
	colour: bool;     //< Use terminal colours
	groups: bool;     //< Print updates about groups
	regression: bool; //< Print regressions results.
	quality: bool;    //< Print quality changes.
	fail: bool;       //< Print non-regression failures.
}

fn printResultsToStdout(ref opts: PrintOptions, suites: Suite[])
{
	info(" :: Printing changes and failing tests.");
	if (!opts.regression && !opts.quality && !opts.fail) {
		info("\tNot printing results as neither regression, quality or failures are printed, use:");
		info("\t--[no-]print-regression");
		info("\t--[no-]print-quality");
		info("\t--[no-]print-fail");
		return;
	}

	foreach (suit; suites) {
		foreach (test; suit.tests) {
			if (test.hasRegressed() && opts.regression) {
				test.printRegression(ref opts);
			} else if (test.hasImproved() && opts.regression) {
				test.printAnyChange(ref opts);
			} else if (test.hasQualityChange() && opts.quality) {
				test.printAnyChange(ref opts);
			} else if (test.hasAnyChangeExceptNotListed() && opts.quality) {
				test.printAnyChange(ref opts);
			} else if (test.hasFailed() && opts.fail) {
				test.printFail(ref opts);
			}
		}
	}
}

fn printResultFromGroup(ref opts: PrintOptions, suite: Suite, tests: Test[],
                        retval: i32, hasFailedTests: bool,
                        start: u32, end: u32, time: string)
{
	if (!opts.groups) {
		return;
	}

	notExpectedRetval := retval != 0 && retval != 1;

	if (notExpectedRetval) {
		prefix := opts.getExclamation();

		// The test run didn't complete.
		if (tests.length == 1) {
			info("\t%s GLES%s bad retval: %s, retval: %s%s", prefix, suite.suffix, tests[0].name, retval, time);
		} else {
			info("\t%s GLES%s bad retval: %s .. %s, retval: %s%s", prefix, suite.suffix, start, end, retval, time);
		}
	} else if (hasFailedTests) {
		prefix := opts.getCross();

		// One or more tests failed.
		if (tests.length == 1) {
			info("\t%s GLES%s test failed: %s%s", prefix, suite.suffix, tests[0].name, time);
		} else {
			info("\t%s GLES%s had failures: %s .. %s%s", prefix, suite.suffix, start, end, time);
		}
	} else {
		prefix := opts.getCheckmark();

		// The test run completed okay.
		if (tests.length == 1) {
			info("\t%s GLES%s done: %s%s", prefix, suite.suffix, tests[0].name, time);
		} else {
			info("\t%s GLES%s done: %s .. %s%s", prefix, suite.suffix, start, end, time);
		}
	}
}

private:


fn printRegression(test: Test, ref opts: PrintOptions)
{
	reg := opts.colour ? "\u001b[41;1mREGRESSED\u001b[0m" : "REGRESSED";
	info("%s %s %s from (%s)", test.name, test.result.format(ref opts), reg, test.compare.format(ref opts));
}

fn printAnyChange(test: Test, ref opts: PrintOptions)
{
	info("%s %s was (%s)", test.name, test.result.format(ref opts), test.compare.format(ref opts));
}

fn printFail(test: Test, ref opts: PrintOptions)
{
	info("%s %s", test.name, test.result.format(ref opts));
}

fn getExclamation(ref opts: PrintOptions) string
{
	if (opts.colour) {
		return "\u001b[41;1m!\u001b[0m";
	} else {
		return "!";
	}
}

fn getCross(ref opts: PrintOptions) string
{
	if (opts.colour) {
		return "\u001b[31m⨯\u001b[0m";
	} else {
		return "⨯";
	}
}

fn getCheckmark(ref opts: PrintOptions) string
{
	if (opts.colour) {
		return "\u001b[32m✔\u001b[0m";
	} else {
		return "✔";
	}
}

fn format(res: Result, ref opts: PrintOptions) string
{
	if (opts.colour) {
		final switch (res) with (Result) {
		case Incomplete:           return "\u001b[31mIncomplete\u001b[0m";
		case Fail:                 return "\u001b[31mFail\u001b[0m";
		case NotSupported:         return "\u001b[34mNotSupported\u001b[0m";
		case InternalError:        return "\u001b[31mInternalError\u001b[0m";
		case BadTerminate:         return "\u001b[31mBadTerminate\u001b[0m";
		case BadTerminatePass:     return "\u001b[31mBadTerminatePass\u001b[0m";
		case QualityWarning:       return "\u001b[33mQualityWarning\u001b[0m";
		case CompatibilityWarning: return "\u001b[33mCompatibilityWarning\u001b[0m";
		case Pass:                 return "\u001b[32mPass\u001b[0m";
		case NotListed:            return "\u001b[32mNotListed\u001b[0m";
		case MalformedResult:      return "\u001b[31mMalformedResult\u001b[0m";
		}
	} else {
		final switch (res) with (Result) {
		case Incomplete:           return "Incomplete";
		case Fail:                 return "Fail";
		case NotSupported:         return "NotSupported";
		case InternalError:        return "InternalError";
		case BadTerminate:         return "BadTerminate";
		case BadTerminatePass:     return "BadTerminatePass";
		case QualityWarning:       return "QualityWarning";
		case CompatibilityWarning: return "CompatibilityWarning";
		case Pass:                 return "Pass";
		case NotListed:            return "NotListed";
		case MalformedResult:      return "MalformedResult";
		}
	}
}
