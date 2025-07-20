# Vim XML/HTML Pretty Printing Test Instructions

## Prerequisites
Make sure you have `xmllint` installed (usually part of libxml2-utils package):
```bash
# Ubuntu/Debian
sudo apt-get install libxml2-utils

# macOS
brew install libxml2
```

## Setup
1. Run the setup script to install the updated .vimrc:
   ```bash
   ./setup.sh
   ```

2. The test files are ready in the current directory:
   - `test_xml.xml` - Minified XML for testing PrettyXml
   - `test_html.html` - Minified HTML for testing PrettyHtml  
   - `test_whitespace.txt` - File with mixed whitespace for testing Showwhitespace

## Testing Instructions

### Test 1: XML Pretty Printing
1. Open the XML test file: `vim test-vim-functions/test_xml.xml`
2. The file should appear as one long line
3. Run the command: `:PrettyXml`
4. **Expected result**: XML should be properly formatted with indentation
5. Save and quit: `:wq`

### Test 2: HTML Pretty Printing
1. Open the HTML test file: `vim test-vim-functions/test_html.html`
2. The file should appear as one long line
3. Run the command: `:PrettyHtml`
4. **Expected result**: HTML should be properly formatted with indentation
5. Save and quit: `:wq`

### Test 3: Whitespace Visualization
1. Open the whitespace test file: `vim test-vim-functions/test_whitespace.txt`
2. Run the command: `:Showwhitespace`
3. **Expected result**: 
   - Tabs should show as `>-----`
   - End of lines should show as `$`
   - Spaces should be visible
4. To turn off: `:set nolist`
5. Quit without saving: `:q!`

### Test 4: Filter Command
1. Open any file with multiple lines: `vim test_xml.xml` (after formatting)
2. Try the filter command: `:Filter property`
3. **Expected result**: New buffer opens with only lines containing "property"
4. Close the filter buffer: `:q`

## What to Check
- [ ] `:PrettyXml` command exists and works
- [ ] `:PrettyHtml` command exists and works  
- [ ] `:Showwhitespace` command exists and works
- [ ] `:Filter` command exists and works
- [ ] No error messages when running commands
- [ ] Formatting actually improves readability
- [ ] Original file types are preserved after formatting

## Troubleshooting
- If `xmllint` command not found: Install libxml2-utils package
- If commands don't exist: Check that setup.sh ran successfully and .vimrc was updated
- If formatting doesn't work: Check that the input files are valid XML/HTML

## Cleanup
```bash
rm test_xml.xml test_html.html test_whitespace.txt TEST_VIM_FUNCTIONS.md
```