Wrapper for `civix generate:module`.

- Calls `civix generate:module` with all given arguments.
- Also copies all files from [this directory]/skel/ to new extension directory.
  (Note: if called again on an existing extension, files from skel will be omitted
  if they already exist in extension dir -- i.e., we won't overwrite those files.)

About skel/ :
- skel/ and its contents are git-ignored.
- You may want to copy skel.dist/ to skel/ as a starting point.