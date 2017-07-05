Example programs interacting with the ZeroMQ XOP
------------------------------------------------

C++ Client
----------

Compilation
~~~~~~~~~~~

- ``mkdir build``
- ``cd build``
- ``cmake -G "Visual Studio 14 2015" ..``
- ``cmake --build . --config Release``

Usage
~~~~~

- Start Igor Pro and execute the following code:

.. code-block:: igorpro
  zeromq_stop()
	zeromq_server_bind("tcp://127.0.0.1:5555")
	zeromq_handler_start()

- Now issue the following command from a command prompt:

``zmq_xop_client.exe "tcp://127.0.0.1:5555" "{ \"version\" : 1, \"CallFunction\" : { \"name\" : \"ZeroMQ_ShowHelp\", \"params\" : [ \"GetDimLabel\" ] } }"``

Igor Pro should now have displayed the help for ``GetDimLabel``.
