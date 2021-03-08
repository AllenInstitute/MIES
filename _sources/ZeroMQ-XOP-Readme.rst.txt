ZeroMQ XOP
==========

The ZeroMQ XOP allows to interface with Igor Pro over the network using `ZeroMQ
<http://www.zeromq.org>`__ as messaging layer and `JSON
<http://www.json.org>`__ as message format.

The XOP provides the following functions:

- :cpp:func:`zeromq_client_connect()`
- :cpp:func:`zeromq_client_recv()`
- :cpp:func:`zeromq_client_send()`
- :cpp:func:`zeromq_server_bind()`
- :cpp:func:`zeromq_server_recv()`
- :cpp:func:`zeromq_server_send()`
- :cpp:func:`zeromq_handler_start()`
- :cpp:func:`zeromq_handler_stop()`
- :cpp:func:`zeromq_stop()`
- :cpp:func:`zeromq_set()`

Installation
~~~~~~~~~~~~

Windows
^^^^^^^

- Quit Igor Pro
- Install the vcredist packages in "output/win"
- Create the following shortcuts in "$HOME\\Documents\\WaveMetrics\\Igor Pro 7 User Files"

  - In "Igor Procedures" a shortcut pointing to "procedures"
  - In "Igor Help Files" a shortcut pointing to "help"
  - In "Igor Extensions" a shortcut pointing to "output/win/x86"
  - In "Igor Extensions (64-bit)" a shortcut pointing to "output/win/x64"

- Start Igor Pro

MacOSX
^^^^^^

- Quit Igor Pro
- Unzip the files in "output/mac"
- Create the following symbolic links (symlinks) in "$HOME/Documents/WaveMetrics/Igor Pro 7 User Files"

  - In "Igor Procedures" a symlink pointing to "procedures"
  - In "Igor Help Files" a symlink pointing to "help"
  - In "Igor Extensions" a symlink pointing to "output/mac/ZeroMQ"
  - In "Igor Extensions (64-bit)" a symlink pointing to "output/mac/ZeroMQ-64"

- Start Igor Pro

In the following the JSON message format is discussed.

Direction: World -> Igor Pro
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Call Igor Pro functions and return the result
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Supported parameter types:

-  string (including pass-by-reference)
-  variable (including pass-by-reference)
-  datafolder reference

Supported return types:

-  string
-  variable
-  wave (without wave reference waves or datafolder reference waves)
-  datafolder reference

Current ``CallFunction`` limitations:

-  Filling in optional parameters is not supported.
-  Passing wave/structure parameters is not supported.

The Igor Pro function ``FooBar(string panelTitle, variable index)`` can
be called by sending the following string

.. code-block:: json

    {
      "version"   : 1,
      "messageID" : "my first message",
       "CallFunction" : {
         "name" : "FooBar",
         "params" : [
            "ITC18USB_DEV_0",
            1
         ]
       }
    }

Calling a function without parameters:

.. code-block:: json

    {
      "version" : 1,
       "CallFunction" : {
         "name" : "FooBarWithoutArgs"
       }
    }

Possible responses:

.. code-block:: json

    {
      "errorCode" : {
       "value" : 0
      },
      "result" : {
        "type" : "variable",
        "value" : 4711
      }
    }

or

.. code-block:: json

    {
      "errorCode" : {
        "value" : 100,
        "msg" : "Function does not exist"
      }
    }

If the function has pass-by-reference parameters their results are
returned as

.. code-block:: json

    {
      "errorCode": {
          "value": 0
      },
      "passByReference": [
          "4711",
          "hi there"
      ],
      "result": {
          "type": "variable",
          "value": 42
      }
    }

Functions can also return datafolder references

.. code-block:: json

    {
      "errorCode" : {
       "value" : 0
      },
      "result" : {
        "type"  : "dfref",
        "value" : "root:MIES"
      }
    }

``result.value`` can also be ``free`` or ``null``.

Functions returning waves
-------------------------

Example wave contents (rows are vertical, colums are horizontal)

+---+------+
| 5 | 8    |
+---+------+
| 6 | -inf |
+---+------+
| 7 | 10   |
+---+------+

Waves with standard settings only:

.. code-block:: json

    {
      "errorCode" : {
       "value" : 0
      },
      "result" : {
        "type"  : "wave",
        "value" : {
          "type"     : "NT_FP64",
          "dimSize"  : [3, 2],
          "date"     : {
            "modification" : 10221232
            },
          "data" : {
            "raw" : [5, 6, 7, 8, "-inf", 10]
            }
          }
      }
    }

In case the function returned an invalid wave reference ``$""``:

.. code-block:: json

    {
      "errorCode" : {
       "value" : 0
      },
      "result" : {
        "type"  : "wave",
        "value" : null
      }
    }

The following is an example where all additional settings are present
because they differ from their default values:

.. code-block:: json

    {
      "errorCode" : {
       "value" : 0
      },
      "result" : {
        "type"  : "wave",
        "value" : {
          "type"     : "NT_FP64",
          "date"     : {
            "modification" : 10221232
            },
          "data" : {
            "raw"       : [5, 6, 7, 8, "-inf", 10],
             "unit"      : "m",
             "fullScale" : [5, 10]
            },
          "dimension" : {
            "size"  : [3, 2],
             "delta" : [1, 2.5],
             "offset": [1e5, 3e7],
             "unit"  : ["kHz", "s"],
             "label" : {
               "full"  : [ "some name", "blah" ],
               "each" : [ "..." ]
              }
          },
           "note" : "Hi there I'm a nice wave note and are encoded in \"UTF8\". With fancy things like ï or ß.",
        }
      }
    }

Direction: Igor Pro -> World
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

not yet implemented

Specification
~~~~~~~~~~~~~

Messages consist of JSON `RFC7158 <https://tools.ietf.org/html/rfc7158>`__
encoded strings with one speciality.  ``NaN``, ``Inf`` and ``-Inf`` are not
supported by JSON, so we encode these non-normal numbers as strings, e.g.
``"NaN"``, ``"Inf"``, ``"+Inf"`` and ``"-Inf"`` (case insensitive).

Sent JSON message
^^^^^^^^^^^^^^^^^

+---------------------+--------------------------+-----------------------+-------------------------------------------------------+----------+
| Name                | JSON type                | Value                 | Description                                           | Required |
+=====================+==========================+=======================+=======================================================+==========+
| version             | string                   | ``v1``                | global for the complete interface                     | Yes      |
+---------------------+--------------------------+-----------------------+-------------------------------------------------------+----------+
| operation           | object                   | ``CallFunction``      | operation which should be performed                   | Yes      |
+---------------------+--------------------------+-----------------------+-------------------------------------------------------+----------+
| CallFunction.name   | string                   | non-empty             | ProcGlobal function without module and or independent |          |
|                     |                          |                       | module specification, i.e. without ``#``.             | Yes      |
+---------------------+--------------------------+-----------------------+-------------------------------------------------------+----------+
| CallFunction.params | array of strings/numbers | holds strings/numbers | function parameters, conversion will be done eagerly. | No       |
+---------------------+--------------------------+-----------------------+-------------------------------------------------------+----------+

Received JSON message for operation ``CallFunction``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

+------------------------+--------------------------+---------------------------------------------------------------------------------------------------------------+
| Name                   | JSON type                | Description                                                                                                   |
+========================+==========================+===============================================================================================================+
| errorCode.value        | number                   | indicates the success/error of the operation, see :cpp:any:`REQ_SUCCESS`                                      |
+------------------------+--------------------------+---------------------------------------------------------------------------------------------------------------+
| errorCode.msg          | string                   | human readable error message, only set if errorCode.value != 0                                                |
+------------------------+--------------------------+---------------------------------------------------------------------------------------------------------------+
| return.type            | string                   | type of the function result, one of ``string``, ``variable``, ``wave`` or ``dfref``, only for errorCode.value |
+------------------------+--------------------------+---------------------------------------------------------------------------------------------------------------+
| return.value           | number, string or object | function result, only for errorCode.value == 0                                                                |
+------------------------+--------------------------+---------------------------------------------------------------------------------------------------------------+
| return.passByReference | array of strings         | Changed parameter values for pass-by-reference parameters.                                                    |
|                        |                          | The fact that ``passByReference`` is an array of strings is an implementation detail and subject to change.   |
+------------------------+--------------------------+---------------------------------------------------------------------------------------------------------------+

Functions returning waves:

- For now the wave data is always returned in a stringified version in
  the reply message itself. Possible enhancement later: Return the
  wave's raw data in binary format in a follow-up message (using zmq's
  multipart message feature).
- Data of text waves and the wave note are encoded in UTF-8.

+-----------------------------------+--------------------------+-------------------------------------------------------------------------------------------------------------------------------------------+
| Name                              | JSON type                | Description                                                                                                                               |
+===================================+==========================+===========================================================================================================================================+
| result.value.type                 | string                   | wave type; one of NT\_FP32, NT\_FP64, NT\_I8, NT\_I16, NT\_I32, NT\_I64, TEXT\_WAVE\_TYPE; or'ed with NT\_UNSIGNED or NT\_CMPLX if needed |
+-----------------------------------+--------------------------+-------------------------------------------------------------------------------------------------------------------------------------------+
| result.value.dimension.size       | array of 1 to 4 numbers  | either "32-bit unsigned int" or "64-bit unsigned int" depending on Igor bitness. An empty wave has ``[0]``.                               |
+-----------------------------------+--------------------------+-------------------------------------------------------------------------------------------------------------------------------------------+
| result.value.dimension.delta      | array of 1 to 4 numbers  | delta values for each dimension                                                                                                           |
+-----------------------------------+--------------------------+-------------------------------------------------------------------------------------------------------------------------------------------+
| result.value.dimension.offset     | array of 1 to 4 numbers  | offset values for each dimension                                                                                                          |
+-----------------------------------+--------------------------+-------------------------------------------------------------------------------------------------------------------------------------------+
| result.value.dimension.label.full | array of strings         | dimension labels for the full dimension                                                                                                   |
+-----------------------------------+--------------------------+-------------------------------------------------------------------------------------------------------------------------------------------+
| result.value.dimension.label.each | array of strings         | dimension labels for each row/column/layer/chunk, colum-major format as ``result.value.data.raw``                                         |
+-----------------------------------+--------------------------+-------------------------------------------------------------------------------------------------------------------------------------------+
| result.value.dimension.unit       | string                   | arbitrary string  denoting the unit. The contents are most likely SI with prefix, but this is not guaranteed.                             |
+-----------------------------------+--------------------------+-------------------------------------------------------------------------------------------------------------------------------------------+
| result.value.date.modification    | number                   | time of last modification in seconds since unix epoch in UTC. 0 for free waves.                                                           |
+-----------------------------------+--------------------------+-------------------------------------------------------------------------------------------------------------------------------------------+
| result.value.data.raw             | array of numbers/strings | column-major format, read it with ``np.array([5, 6, 7, 8, "-inf", 10]).reshape(3, 2, order='F')`` using Python.                           |
|                                   |                          | For complex waves ``raw`` has two properties ``real`` and ``imag`` both holding arrays.                                                   |
+-----------------------------------+--------------------------+-------------------------------------------------------------------------------------------------------------------------------------------+
| result.value.data.unit            | string                   | arbitrary strings denoting the unit. The contents are most likely SI with prefix, but this is not guaranteed.                             |
+-----------------------------------+--------------------------+-------------------------------------------------------------------------------------------------------------------------------------------+
| result.value.data.fullScale       | array of numbers/strings | min and max of the data (non-authorative)                                                                                                 |
+-----------------------------------+--------------------------+-------------------------------------------------------------------------------------------------------------------------------------------+
| result.value.note                 | string                   | wave note                                                                                                                                 |
+-----------------------------------+--------------------------+-------------------------------------------------------------------------------------------------------------------------------------------+

Compilation instructions
^^^^^^^^^^^^^^^^^^^^^^^^

Required additional software:

- (Windows only) Visual Studio 2015
- (MacOSX only) Xcode
- `CMake <https://cmake.org>`__ version 3.8 or later
- `XOPSupport Toolkit 7 <https://www.wavemetrics.com/products/xoptoolkit/xoptoolkit.htm>`__
- `Igor Unit Testing Framework <https://github.com/byte-physics/igor-unit-testing-framework>`__

Building libzmq
~~~~~~~~~~~~~~~

.. code-block:: sh

    cd libzmq
    mkdir build build-64

    # WINDOWS
    # {
    # 32bit
    cd build
    cmake -G "Visual Studio 14 2015" ..
    cmake --build . --config Release
    ctest -C Release
    # Import/static libs are in lib/release, dll in bin/release

    # 64bit
    cd build-64
    cmake -G "Visual Studio 14 2015 Win64" ..
    cmake --build . --config Release
    ctest -C Release
    # Import/static libs are in lib/release, dll in bin/release
    # }

    # MACOSX
    # {
    # 32bit
    cd build
    cmake -DCMAKE_OSX_ARCHITECTURES=i386 -DCMAKE_OSX_DEPLOYMENT_TARGET=10.9 ..
    cmake --build . --config Release
    ctest -C Release
    # static libs are in lib

    # 64bit
    mkdir build-64
    cd build-64
    cmake -DCMAKE_OSX_ARCHITECTURES=x86_64 -DCMAKE_OSX_DEPLOYMENT_TARGET=10.9 ..
    cmake --build . --config Release
    ctest -C Release
    # static libs are in lib
    # }

Building and installing the ZeroMQ.xop
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: sh

   # Windows
   # {
   # Install cmake from www.cmake.org
   # Install Visual Studio 2015 Community
   # Open a Visual Studio 2015 command prompt
   cd Packages/ZeroMQ/src
   mkdir build build-64
   cmake -G "Visual Studio 14 2015" ..
   cmake --build . --config Release --target install
   cd ..
   cmake -G "Visual Studio 14 2015 Win64" ..
   cmake --build . --config Release --target install
   # }

   # MacOSX
   # {
   cmake -DCMAKE_OSX_ARCHITECTURES=i386 -DCMAKE_OSX_DEPLOYMENT_TARGET=10.9 -G Xcode ..
   cmake --build . --config Release --target install
   cd ..
   cmake -DCMAKE_OSX_ARCHITECTURES=x86_64 -DCMAKE_OSX_DEPLOYMENT_TARGET=10.9 -G Xcode ..
   cmake --build . --config Release --target install
   # }

Running the test suite
~~~~~~~~~~~~~~~~~~~~~~

- Create in "Igor Procedures" a shortcut pointing to
  ``Packages\unit-testing``
- Open Packages/ZeroMQ/tests/RunTests.pxp
- Execute in Igor ``run()``
- The test suite always passes *without* errors

Running clang-tidy on MacOSX
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- Install `Homebrew <https://brew.sh>`__
- ``brew install llvm``
- Create compilation database

  - ``mkdir clang-tidy; cd clang-tidy``
  - ``cmake -DCMAKE_OSX_ARCHITECTURES=x86_64 -DCMAKE_OSX_DEPLOYMENT_TARGET=10.9 -DCMAKE_EXPORT_COMPILE_COMMANDS=ON ..``
  - ``cmake --build . --target clang-tidy``

ZeroMQ XOP implementation details
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The XOP uses the ``Dealer`` (called Client in the XOP interface) and ``Router`` (called Server in the XOP interface) socket types.

The default socket options are:

- ``ZMQ_LINGER``           = ``0``
- ``ZMQ_SNDTIMEO``         = ``0``
- ``ZMQ_RCVTIMEO``         = ``0``
- ``ZMQ_ROUTER_MANDATORY`` = ``1`` (``Router`` only)
- ``ZMQ_MAXMSGSIZE``       = ``1024`` (in bytes, ``Router`` only)
- ``ZMQ_IDENTITY``         = ``zeromq xop: dealer`` (``Dealer`` only)

The ``Router``/Server expects three frames (identity, empty, payload) and the
``Dealer``/Client expects two frames (empty, payload) when sending/receiving
messages. This format is used to be compatible with REP/REQ sockets.

The passed function in the JSON message is currently always executed in the
main thread during ``IDLE`` events. ``IDLE`` events are generated by Igor Pro
only when no functions are running. In case you want to execute a function
during the time when functions are running the operation ``DoXOPIdle`` allows
to force an ``IDLE`` event.
