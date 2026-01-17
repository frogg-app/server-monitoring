#!/usr/bin/env python3
"""
Pulse Server Monitoring - Integration Test Suite

This test suite validates the API endpoints and web app functionality.
Run with: python3 tests/integration_test.py

Requirements: pip install requests
"""

import argparse
import json
import sys
import time
from dataclasses import dataclass
from typing import Optional
import urllib.request
import urllib.error

# ANSI color codes
GREEN = '\033[92m'
RED = '\033[91m'
YELLOW = '\033[93m'
BLUE = '\033[94m'
RESET = '\033[0m'
BOLD = '\033[1m'


@dataclass
class TestResult:
    name: str
    passed: bool
    message: str
    duration_ms: float


class PulseTestSuite:
    """Integration test suite for Pulse Server Monitoring"""
    
    def __init__(self, api_url: str, web_url: Optional[str] = None):
        self.api_url = api_url.rstrip('/')
        self.web_url = web_url.rstrip('/') if web_url else None
        self.results: list[TestResult] = []
        self.access_token: Optional[str] = None
        self.refresh_token: Optional[str] = None
    
    def _request(self, method: str, path: str, data: Optional[dict] = None,
                 headers: Optional[dict] = None, expected_status: int = 200) -> tuple[int, dict]:
        """Make an HTTP request and return status code and response data"""
        url = f"{self.api_url}{path}"
        req_headers = {'Content-Type': 'application/json'}
        if headers:
            req_headers.update(headers)
        if self.access_token:
            req_headers['Authorization'] = f'Bearer {self.access_token}'
        
        body = json.dumps(data).encode() if data else None
        req = urllib.request.Request(url, data=body, headers=req_headers, method=method)
        
        try:
            with urllib.request.urlopen(req, timeout=10) as response:
                status = response.status
                try:
                    resp_data = json.loads(response.read().decode())
                except json.JSONDecodeError:
                    resp_data = {}
        except urllib.error.HTTPError as e:
            status = e.code
            try:
                resp_data = json.loads(e.read().decode())
            except json.JSONDecodeError:
                resp_data = {'error': str(e)}
        except urllib.error.URLError as e:
            return -1, {'error': str(e)}
        
        return status, resp_data
    
    def _web_request(self, path: str = '/') -> tuple[int, str]:
        """Make an HTTP request to the web app"""
        if not self.web_url:
            return -1, "Web URL not configured"
        
        url = f"{self.web_url}{path}"
        req = urllib.request.Request(url)
        
        try:
            with urllib.request.urlopen(req, timeout=10) as response:
                return response.status, response.read().decode()
        except urllib.error.HTTPError as e:
            return e.code, str(e)
        except urllib.error.URLError as e:
            return -1, str(e)
    
    def run_test(self, name: str, test_func) -> bool:
        """Run a single test and record the result"""
        start_time = time.time()
        try:
            passed, message = test_func()
            duration_ms = (time.time() - start_time) * 1000
            self.results.append(TestResult(name, passed, message, duration_ms))
            
            status = f"{GREEN}PASS{RESET}" if passed else f"{RED}FAIL{RESET}"
            print(f"  {status} {name} ({duration_ms:.1f}ms)")
            if not passed:
                print(f"       {YELLOW}{message}{RESET}")
            return passed
        except Exception as e:
            duration_ms = (time.time() - start_time) * 1000
            self.results.append(TestResult(name, False, str(e), duration_ms))
            print(f"  {RED}FAIL{RESET} {name} ({duration_ms:.1f}ms)")
            print(f"       {YELLOW}{e}{RESET}")
            return False

    # ==================== API Tests ====================
    
    def test_health_endpoint(self) -> tuple[bool, str]:
        """Test /health endpoint"""
        status, data = self._request('GET', '/health')
        if status != 200:
            return False, f"Expected 200, got {status}"
        if data.get('status') != 'ok':
            return False, f"Expected status 'ok', got '{data.get('status')}'"
        return True, "Health check passed"
    
    def test_api_v1_health_endpoint(self) -> tuple[bool, str]:
        """Test /api/v1/health endpoint"""
        status, data = self._request('GET', '/api/v1/health')
        if status != 200:
            return False, f"Expected 200, got {status}"
        if data.get('status') != 'ok':
            return False, f"Expected status 'ok', got '{data.get('status')}'"
        if 'version' not in data:
            return False, "Missing version field"
        if 'uptime' not in data:
            return False, "Missing uptime field"
        return True, f"API version: {data.get('version')}"
    
    def test_login_invalid_credentials(self) -> tuple[bool, str]:
        """Test login with invalid credentials"""
        status, data = self._request('POST', '/api/v1/auth/login', {
            'username': 'invalid',
            'password': 'wrongpassword'
        })
        if status != 401:
            return False, f"Expected 401, got {status}"
        return True, "Invalid credentials rejected"
    
    def test_login_missing_fields(self) -> tuple[bool, str]:
        """Test login with missing fields"""
        status, data = self._request('POST', '/api/v1/auth/login', {})
        if status not in [400, 401]:
            return False, f"Expected 400 or 401, got {status}"
        return True, "Missing fields rejected"
    
    def test_protected_endpoint_without_auth(self) -> tuple[bool, str]:
        """Test accessing protected endpoint without authentication"""
        old_token = self.access_token
        self.access_token = None
        try:
            status, data = self._request('GET', '/api/v1/auth/me')
            if status != 401:
                return False, f"Expected 401, got {status}"
            return True, "Protected endpoint requires auth"
        finally:
            self.access_token = old_token
    
    def test_protected_endpoint_invalid_token(self) -> tuple[bool, str]:
        """Test accessing protected endpoint with invalid token"""
        old_token = self.access_token
        self.access_token = 'invalid.token.here'
        try:
            status, data = self._request('GET', '/api/v1/auth/me')
            if status != 401:
                return False, f"Expected 401, got {status}"
            return True, "Invalid token rejected"
        finally:
            self.access_token = old_token
    
    def test_logout_without_token(self) -> tuple[bool, str]:
        """Test logout without refresh token"""
        status, data = self._request('POST', '/api/v1/auth/logout', {})
        # Should fail without proper token
        if status in [400, 401]:
            return True, "Logout without token rejected"
        return False, f"Expected 400 or 401, got {status}"
    
    def test_refresh_without_token(self) -> tuple[bool, str]:
        """Test token refresh without refresh token"""
        status, data = self._request('POST', '/api/v1/auth/refresh', {})
        if status in [400, 401]:
            return True, "Refresh without token rejected"
        return False, f"Expected 400 or 401, got {status}"

    # ==================== Web App Tests ====================
    
    def test_web_app_serves_html(self) -> tuple[bool, str]:
        """Test that web app serves HTML"""
        if not self.web_url:
            return True, "Skipped (no web URL configured)"
        
        status, content = self._web_request('/')
        if status != 200:
            return False, f"Expected 200, got {status}"
        if '<!DOCTYPE html>' not in content.lower() and '<html' not in content.lower():
            return False, "Response is not HTML"
        return True, "Web app serves HTML"
    
    def test_web_app_flutter_assets(self) -> tuple[bool, str]:
        """Test that Flutter assets are served"""
        if not self.web_url:
            return True, "Skipped (no web URL configured)"
        
        status, content = self._web_request('/main.dart.js')
        if status != 200:
            return False, f"Expected 200 for main.dart.js, got {status}"
        return True, "Flutter JS bundle found"
    
    def test_web_app_api_proxy(self) -> tuple[bool, str]:
        """Test that web app proxies API requests"""
        if not self.web_url:
            return True, "Skipped (no web URL configured)"
        
        url = f"{self.web_url}/api/v1/health"
        req = urllib.request.Request(url)
        try:
            with urllib.request.urlopen(req, timeout=10) as response:
                if response.status != 200:
                    return False, f"Expected 200, got {response.status}"
                data = json.loads(response.read().decode())
                if data.get('status') != 'ok':
                    return False, "API proxy returned invalid data"
                return True, "API proxy working"
        except Exception as e:
            return False, str(e)
    
    def test_web_app_spa_routing(self) -> tuple[bool, str]:
        """Test that SPA routing works (returns index.html for unknown routes)"""
        if not self.web_url:
            return True, "Skipped (no web URL configured)"
        
        status, content = self._web_request('/login')
        if status != 200:
            return False, f"Expected 200 for SPA route, got {status}"
        if '<!DOCTYPE html>' not in content.lower() and '<html' not in content.lower():
            return False, "SPA route did not return index.html"
        return True, "SPA routing works"

    # ==================== Test Runner ====================
    
    def run_all_tests(self) -> bool:
        """Run all tests and return overall success status"""
        print(f"\n{BOLD}{'='*60}{RESET}")
        print(f"{BOLD}Pulse Server Monitoring - Integration Tests{RESET}")
        print(f"{BOLD}{'='*60}{RESET}")
        print(f"\nAPI URL: {BLUE}{self.api_url}{RESET}")
        if self.web_url:
            print(f"Web URL: {BLUE}{self.web_url}{RESET}")
        print()
        
        # API Health Tests
        print(f"\n{BOLD}API Health Tests{RESET}")
        print("-" * 40)
        self.run_test("Health endpoint (/health)", self.test_health_endpoint)
        self.run_test("API v1 health (/api/v1/health)", self.test_api_v1_health_endpoint)
        
        # Authentication Tests
        print(f"\n{BOLD}Authentication Tests{RESET}")
        print("-" * 40)
        self.run_test("Login - invalid credentials", self.test_login_invalid_credentials)
        self.run_test("Login - missing fields", self.test_login_missing_fields)
        self.run_test("Protected endpoint - no auth", self.test_protected_endpoint_without_auth)
        self.run_test("Protected endpoint - invalid token", self.test_protected_endpoint_invalid_token)
        self.run_test("Logout - without token", self.test_logout_without_token)
        self.run_test("Refresh - without token", self.test_refresh_without_token)
        
        # Web App Tests
        if self.web_url:
            print(f"\n{BOLD}Web App Tests{RESET}")
            print("-" * 40)
            self.run_test("Serves HTML", self.test_web_app_serves_html)
            self.run_test("Flutter JS bundle", self.test_web_app_flutter_assets)
            self.run_test("API proxy", self.test_web_app_api_proxy)
            self.run_test("SPA routing", self.test_web_app_spa_routing)
        
        # Summary
        passed = sum(1 for r in self.results if r.passed)
        failed = sum(1 for r in self.results if not r.passed)
        total = len(self.results)
        total_time = sum(r.duration_ms for r in self.results)
        
        print(f"\n{BOLD}{'='*60}{RESET}")
        print(f"{BOLD}Test Summary{RESET}")
        print(f"{'='*60}")
        print(f"  Total:  {total}")
        print(f"  Passed: {GREEN}{passed}{RESET}")
        print(f"  Failed: {RED}{failed}{RESET}")
        print(f"  Time:   {total_time:.1f}ms")
        print(f"{'='*60}\n")
        
        if failed == 0:
            print(f"{GREEN}{BOLD}✓ All tests passed!{RESET}\n")
            return True
        else:
            print(f"{RED}{BOLD}✗ {failed} test(s) failed{RESET}\n")
            return False


def main():
    parser = argparse.ArgumentParser(description='Pulse Integration Test Suite')
    parser.add_argument('--api-url', default='http://localhost:8080',
                        help='API base URL (default: http://localhost:8080)')
    parser.add_argument('--web-url', default=None,
                        help='Web app URL (optional)')
    parser.add_argument('--wait', type=int, default=0,
                        help='Wait seconds before running tests')
    args = parser.parse_args()
    
    if args.wait > 0:
        print(f"Waiting {args.wait} seconds for services to start...")
        time.sleep(args.wait)
    
    suite = PulseTestSuite(args.api_url, args.web_url)
    success = suite.run_all_tests()
    sys.exit(0 if success else 1)


if __name__ == '__main__':
    main()
