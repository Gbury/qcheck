(*
QCheck: Random testing for OCaml
copyright (c) 2013-2017, Guillaume Bury, Simon Cruanes, Vincent Hugot, Jan Midtgaard
all rights reserved.
*)

(** {1 Runners for Tests}

    Once you built some tests using {!QCheck.Test.make}, you need to
    run the tests. This module contains several {b runners},
    which are designed to run every test and report the result.

    By default, you can use {!run_tests} in a test program as follows:
    {[
      let testsuite = [
        Test.make ...;
        Test.make ...;
      ]

      let () =
        let errcode = QCheck_runners.run_tests ~verbose:true testsuite in
        exit errcode
    ]}
    which will run the tests, and exit the program. The error code
    will be 0 if all tests pass, 1 otherwise.

    {!run_tests_main} can be used as a shortcut for that, also
    featuring command-line parsing (using {!Arg}) to activate
    verbose mode and others.
*)

(** {2 State} *)

val random_state : unit -> Random.State.t
(** Access the current random state *)

val verbose : unit -> bool
(** Is the default mode verbose or quiet? *)

val long_tests : unit -> bool
(** Is the default mode to run long tests or nor? *)

val set_seed : int -> unit
(** Change the {!random_state} by creating a new one, initialized with
    the given seed. *)

val set_verbose : bool -> unit
(** Change the value of [verbose ()] *)

val set_long_tests : bool -> unit
(** Change the value of [long_tests ()] *)

val get_time_between_msg : unit -> float
(** Get the minimum time to wait between printing messages. *)

val set_time_between_msg : float -> unit
(** Set the minimum tiem between messages. *)

(** {2 Conversion of tests to OUnit Tests} *)

val to_ounit_test :
  ?verbose:bool -> ?long:bool -> ?rand:Random.State.t ->
  QCheck.Test.t -> OUnit.test
(** [to_ounit_test ~rand t] wraps [t] into a OUnit test
    @param verbose used to print information on stdout (default: [verbose()])
    @param rand the random generator to use (default: [random_state ()]) *)

val to_ounit_test_cell :
  ?verbose:bool -> ?long:bool -> ?rand:Random.State.t ->
  _ QCheck.Test.cell -> OUnit.test
(** Same as {!to_ounit_test} but with a polymorphic test cell *)

val (>:::) : string -> QCheck.Test.t list -> OUnit.test
(** Same as {!OUnit.>:::} but with a list of QCheck tests *)

val to_ounit2_test : ?rand:Random.State.t -> QCheck.Test.t -> OUnit2.test
(** [to_ounit2_test ?rand t] wraps [t] into a OUnit2 test
    @param rand the random generator to use (default: a static seed for reproducibility),
    can be overridden with "-seed" on the command-line
*)

val to_ounit2_test_list : ?rand:Random.State.t -> QCheck.Test.t list -> OUnit2.test list
(** [to_ounit2_test_list ?rand t] like [to_ounit2_test] but for a list of tests *)

(** {2 OUnit runners} *)

val run : ?argv:string array -> OUnit.test -> int
(** [run test] runs the test, and returns an error code  that is [0]
    if all tests passed, [1] otherwise.
    This is the default runner used by the comment-to-test generator.

    @param argv the command line arguments to parse parameters from (default [Sys.argv])
    @raise Arg.Bad in case [argv] contains unknown arguments
    @raise Arg.Help in case [argv] contains "--help"

    This test runner displays execution in a compact way, making it good
    for suites that have lots of tests.

    Output example: {v
random seed: 101121210
random seed: 101121210
\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
Error: tests>error_raise_exn

test `error_raise_exn` raised exception `QCheck_ounit_test.Error`
on `0 (after 62 shrink steps)`
Raised at file "example/QCheck_ounit_test.ml", line 19, characters 20-25
Called from file "src/QCheck.ml", line 846, characters 13-33

///////////////////////////////////////////////////////////////////////////////
\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
Failure: tests>fail_sort_id

fail_sort_id
///////////////////////////////////////////////////////////////////////////////
Ran: 4 tests in: 0.74 seconds.
WARNING! SOME TESTS ARE NEITHER SUCCESSES NOR FAILURES!
v}
*)

val run_tap : OUnit.test -> OUnit.test_results
(** TAP-compatible test runner, in case we want to use a test harness.
    It prints one line per test. *)

(** {2 Run a Suite of Tests and Get Results} *)

val run_tests :
  ?colors:bool -> ?verbose:bool -> ?long:bool ->
  ?out:out_channel -> ?rand:Random.State.t ->
  QCheck.Test.t list -> int
(** Run a suite of tests, and print its results. This is an heritage from
    the "qcheck" library.
    @return an error code, [0] if all tests passed, [1] otherwise.
    @param colors if true, colorful output
    @param verbose if true, prints more information about test cases *)

val run_tests_main : ?argv:string array -> QCheck.Test.t list -> 'a
(** Can be used as the main function of a test file. Exits with a non-0 code
    if the tests fail. It refers to {!run_tests} for actually running tests
    after CLI options have been parsed.

    The available options are:

    - "--verbose" (or "-v") for activating verbose tests
    - "--seed <n>" (or "-s <n>") for repeating a previous run by setting the random seed
    - "--long" for running the long versions of the tests

    Below is an example of the output of the [run_tests] and [run_tests_main]
    function: {v
random seed: 438308050
generated  error;  fail; pass / total -     time -- test name
[✓] (1000)    0 ;    0 ; 1000 / 1000 --     0.5s -- list_rev_is_involutive
[✗] (   1)    0 ;    1 ;    0 /   10 --     0.0s -- should_fail_sort_id
[✗] (   1)    1 ;    0 ;    0 /   10 --     0.0s -- should_error_raise_exn
[✓] (1000)    0 ;    0 ; 1000 / 1000 --     0.0s -- collect_results

--- Failure --------------------------------------------------------------------

Test should_fail_sort_id failed (11 shrink steps):

[1; 0]

=== Error ======================================================================

Test should_error_raise_exn errored on (62 shrink steps):

0

exception QCheck_runner_test.Error
Raised at file "example/QCheck_runner_test.ml", line 20, characters 20-25
Called from file "src/QCheck.ml", line 839, characters 13-33


+++ Collect ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

Collect results for test collect_results:

4: 207 cases
3: 190 cases
2: 219 cases
1: 196 cases
0: 188 cases

================================================================================
failure (1 tests failed, 1 tests errored, ran 4 tests)
v}
*)
