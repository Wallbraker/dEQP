// Copyright 2018, Collabora Inc.
// SPDX-License-Identifier: BSL-1.0
/*!
 * Contains code and classes for managing tests results.
 */
module deqp.tests.result;

import deqp.tests.test;


/*!
 * Big enum with all of the status that a test can return.
 * Has extra status to account for dEQP crashing.
 */
enum Result
{
	Incomplete,
	Fail,
	NotSupported,
	InternalError,
	BadTerminate,
	BadTerminatePass,
	QualityWarning,
	CompatibilityWarning,
	Pass,
	NotListed, //< For compare, the test wasn't in the regression file.
}

fn isResultPassing(result: Result) bool
{
	final switch (result) with (Result) {
	case Incomplete:           return false;
	case Fail:                 return false;
	case NotSupported:         return false;
	case InternalError:        return false;
	case BadTerminate:         return false;
	case BadTerminatePass:     return false;
	case QualityWarning:       return true;
	case CompatibilityWarning: return true;
	case Pass:                 return true;
	case NotListed:            return true;
	}
}

fn isResultFailing(result: Result) bool
{
	final switch (result) with (Result) {
	case Incomplete:           return true;
	case Fail:                 return true;
	case NotSupported:         return false;
	case InternalError:        return true;
	case BadTerminate:         return true;
	case BadTerminatePass:     return true;
	case QualityWarning:       return false;
	case CompatibilityWarning: return false;
	case Pass:                 return false;
	case NotListed:            return false;
	}
}

fn isResultAndCompareImprovement(result: Result, compare: Result) bool
{
	if (result.isResultPassing()) {
		return compare.isResultFailing();
	} else {
		return false;
	}
}

fn isResultAndCompareRegression(result: Result, compare: Result) bool
{
	if (result.isResultFailing()) {
		return compare.isResultPassing();
	} else {
		return false;
	}
}

fn isResultAndCompareQualityChange(result: Result, compare: Result) bool
{
	if (compare == Result.NotListed) {
		compare = Result.Pass;
	}

	if (result.isResultPassing() && compare.isResultPassing()) {
		return result != compare;
	} else {
		return false;
	}
}

fn isResultAndCompareAnyChangeExceptNotListed(result: Result, compare: Result) bool
{
	if (compare == Result.NotListed) {
		return false;
	}

	if (result != compare) {
		return true;
	} else {
		return false;
	}
}

fn isResultAndCompareAnyChange(result: Result, compare: Result) bool
{
	if (result != compare) {
		return true;
	} else {
		return false;
	}
}

struct Results
{
public:
	numFail: u32;
	numIncomplete: u32;
	numInternalError: u32;
	numNotSupported: u32;
	numBadTerminate: u32;
	numBadTerminatePass: u32;
	numPass: u32;
	numQualityWarning: u32;
	numCompatibilityWarning: u32;

	suites: Suite[];


public:
	fn getPass() u32
	{
		return numPass;
	}

	fn getWarn() u32
	{
		return numQualityWarning + numCompatibilityWarning;
	}

	fn getBad() u32
	{
		return numIncomplete + numFail + numInternalError +
			numBadTerminate + numBadTerminatePass;
	}

	fn getSkip() u32
	{
		return numNotSupported;
	}

	fn getIncomplete() u32
	{
		return numIncomplete + numBadTerminate + numBadTerminatePass;
	}

	fn getTotal() u32
	{
		return numFail + numIncomplete + numInternalError +
		       numNotSupported + numPass + numQualityWarning +
		       numIncomplete + numInternalError +
		       numCompatibilityWarning;
	}

	fn count()
	{
		// Reset the old numbers.
		numFail = numIncomplete = numInternalError = numNotSupported =
			numBadTerminate = numBadTerminatePass = numPass =
			numQualityWarning = numCompatibilityWarning =  0;

		foreach (suite; suites) {
			foreach (test; suite.tests) {
				final switch (test.result) with (Result) {
				case Incomplete: numIncomplete++; break;
				case Fail: numFail++; break;
				case InternalError: numInternalError++; break;
				case BadTerminate: numBadTerminate++; break;
				case BadTerminatePass: numBadTerminatePass++; break;
				case QualityWarning: numQualityWarning++; break;
				case CompatibilityWarning: numCompatibilityWarning++; break;
				case Pass: numPass++; break;
				case NotSupported: numNotSupported++; break;
				case NotListed: break;
				}
			}
		}
	}
}
