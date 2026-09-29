"""Create a blank raw sector for the Hall of Fame save data."""

import sys
from pathlib import Path


Path(sys.argv[1]).write_bytes(bytes(512))
