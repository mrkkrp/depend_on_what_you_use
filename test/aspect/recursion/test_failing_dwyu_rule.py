from result import ExpectedResult, Result
from test_case import TestCaseBase


class TestCase(TestCaseBase):
    def execute_test_logic(self) -> Result:
        expected = ExpectedResult(success=False, unused_public_deps=["//test/aspect/recursion:e"])
        actual = self._run_bazel_build(target="//test/aspect/recursion:dwyu_recursive_main")

        return self._check_result(actual=actual, expected=expected)
