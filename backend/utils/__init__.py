"""Utility scripts for the MediHive Marathi backend.

This module provides helper functions and a common path-setup
routine that makes all utility scripts runnable both via:

    python backend/utils/<script>.py
    python -m backend.utils.<script>
"""

from __future__ import annotations

import os
import sys


def setup_path() -> None:
    """Ensure backend/ is importable when running scripts directly.

    Adds the parent of backend/utils/ to sys.path so that
    ``from backend.config.google_config import config`` works
    regardless of how the script is invoked.
    """
    current = os.path.dirname(os.path.abspath(__file__))
    backend_dir = os.path.dirname(current)
    if backend_dir not in sys.path:
        sys.path.insert(0, backend_dir)
