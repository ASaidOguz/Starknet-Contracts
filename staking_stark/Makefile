# Coverage Report Generation
PROJECT_NAME ?= staking_stark
REPORT_DIR = coverage_report
REPORTS_BASE = /mnt/c/stark-reports/coverage-reports
PROJECT_REPORT_DIR = $(REPORTS_BASE)/$(PROJECT_NAME)

WINDOWS_REPORT_DIR = C:\\stark-reports\\coverage-reports\\$(PROJECT_NAME)
CHROME_PATH ?= C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe
clean_coverage:
	cairo-coverage	clean

test_coverage:
	snforge test --coverage
	genhtml -o $(REPORT_DIR) ./coverage/coverage.lcov
	mkdir -p $(PROJECT_REPORT_DIR)
	cp -r $(REPORT_DIR)/* $(PROJECT_REPORT_DIR)/
	powershell.exe -Command "Start-Process '$(CHROME_PATH)' -ArgumentList '$(WINDOWS_REPORT_DIR)\\index.html'"
