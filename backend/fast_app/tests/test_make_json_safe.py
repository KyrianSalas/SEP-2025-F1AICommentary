"""Unit tests for the make_json_safe method in PlaybackEngine."""
import pytest
import pandas as pd
import numpy as np
from fast_app.playback_engine import PlaybackEngine


class TestMakeJsonSafe:
    """Test suite for the make_json_safe data conversion method."""

    def setup_method(self):
        """Set up a minimal PlaybackEngine instance for testing."""
        df = pd.DataFrame({
            'Time': pd.to_timedelta([0], unit='s'),
            'X': [0.0],
            'Y': [0.0],
            'Speed': [0]
        })
        self.engine = PlaybackEngine(
            drivers_data={"TEST": df},
            session_info={"event": "Test"}
        )

    def test_handles_nan_values(self):
        """NaN values should be converted to None so the frontend can fall back to the last valid reading."""
        result = self.engine.make_json_safe(float('nan'))
        assert result is None

    def test_handles_infinity(self):
        """Infinity values should be converted to None so the frontend can fall back to the last valid reading."""
        result = self.engine.make_json_safe(float('inf'))
        assert result is None
        result_neg = self.engine.make_json_safe(float('-inf'))
        assert result_neg is None

    def test_handles_numpy_int(self):
        """Numpy integers should be converted to Python int."""
        result = self.engine.make_json_safe(np.int64(42))
        assert result == 42
        assert isinstance(result, int)

    def test_handles_numpy_float(self):
        """Numpy floats should be converted to Python float."""
        result = self.engine.make_json_safe(np.float64(3.14))
        assert result == 3.14
        assert isinstance(result, float)

    def test_handles_pandas_timestamp(self):
        """Pandas Timestamp should be converted to string."""
        ts = pd.Timestamp('2024-01-01 12:00:00')
        result = self.engine.make_json_safe(ts)
        assert isinstance(result, str)

    def test_handles_pandas_timedelta(self):
        """Pandas Timedelta should be converted to total seconds."""
        td = pd.Timedelta(seconds=90)
        result = self.engine.make_json_safe(td)
        assert result == 90.0

    def test_handles_numpy_bool(self):
        """Numpy booleans should be converted to Python bool."""
        result_true = self.engine.make_json_safe(np.bool_(True))
        result_false = self.engine.make_json_safe(np.bool_(False))
        assert result_true is True
        assert result_false is False
        assert isinstance(result_true, bool)

    def test_handles_nested_dict(self):
        """Nested dictionaries with mixed types should be fully converted."""
        data = {
            'speed': np.float64(150.5),
            'gear': np.int64(4),
            'time': pd.Timedelta(seconds=30)
        }
        result = self.engine.make_json_safe(data)
        assert result['speed'] == 150.5
        assert result['gear'] == 4
        assert result['time'] == 30.0

    def test_handles_list_with_mixed_types(self):
        """Lists with mixed numpy types should be fully converted."""
        data = [np.int64(1), np.float64(2.5), 'text', np.bool_(True)]
        result = self.engine.make_json_safe(data)
        assert result == [1, 2.5, 'text', True]

    def test_regular_python_types_pass_through(self):
        """Regular Python types should pass through unchanged."""
        assert self.engine.make_json_safe(42) == 42
        assert self.engine.make_json_safe(3.14) == 3.14
        assert self.engine.make_json_safe('hello') == 'hello'
        assert self.engine.make_json_safe(True) is True
        assert self.engine.make_json_safe(None) is None
