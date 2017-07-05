#include <zmq.h>
#include <string>
#include <iostream>

#define ZEROMQ_ASSERT(A)                                             \
  if(!(A))                                                           \
  {                                                                  \
    auto err = zmq_errno();                                          \
    fprintf(stderr, "The zmq library call in %s line %d file "       \
            "%s failed with errno=%d and msg=\"%s\"\r",              \
            __func__, __LINE__, __FILE__, err, zmq_strerror(err));   \
    exit(1);                                                         \
  }

int main(int argc, char** argv)
{
  if(argc < 3)
  {
    std::cerr << "Expected exactly two arguments." << std::endl;
    std::cerr << "First argument: remote point to connect to" << std::endl;
    std::cerr << "Second argument: JSON message to send" << std::endl;
    exit(1);
  }

  const std::string remotePoint(argv[1]);
  const std::string payload(argv[2]);

  std::cout << "Remote point: " << remotePoint << std::endl;
  std::cout << "JSON Message: " << payload     << std::endl;

  auto zmq_context = zmq_ctx_new();
  ZEROMQ_ASSERT(zmq_context != nullptr);

  auto zmq_client_socket = zmq_socket(zmq_context, ZMQ_DEALER);
  ZEROMQ_ASSERT(zmq_client_socket != nullptr);

  int val = 0;
  auto rc = zmq_setsockopt(zmq_client_socket, ZMQ_LINGER, &val, sizeof(val));
  ZEROMQ_ASSERT(rc == 0);

  const char identity[] = "cli client for xop: dealer";
  rc = zmq_setsockopt(zmq_client_socket, ZMQ_IDENTITY, &identity, strlen(identity));
  ZEROMQ_ASSERT(rc == 0);

  rc = zmq_connect(zmq_client_socket, remotePoint.c_str());
  ZEROMQ_ASSERT(rc == 0);

  // empty message
  rc = zmq_send(zmq_client_socket, NULL, 0, ZMQ_SNDMORE);
  ZEROMQ_ASSERT(rc == 0);

  // payload
  rc = zmq_send(zmq_client_socket, payload.c_str(), payload.size(), 0);
  ZEROMQ_ASSERT(rc > 0);

  zmq_msg_t payloadMsg;
  rc = zmq_msg_init(&payloadMsg);
  ZEROMQ_ASSERT(rc == 0);

  // wait for reply
  // empty
  auto numBytes = zmq_msg_recv(&payloadMsg, zmq_client_socket, 0);
  ZEROMQ_ASSERT(numBytes >= 0);
  ZEROMQ_ASSERT(zmq_msg_more(&payloadMsg))

  // payload
  numBytes = zmq_msg_recv(&payloadMsg, zmq_client_socket, 0);

  std::string reply(static_cast<char*>(zmq_msg_data(&payloadMsg)), zmq_msg_size(&payloadMsg));

  std::cout << "Reply: " << reply << std::endl;

  rc = zmq_msg_close(&payloadMsg);
  ZEROMQ_ASSERT(rc == 0);

  rc = zmq_disconnect(zmq_client_socket, remotePoint.c_str());
  ZEROMQ_ASSERT(rc == 0);

  rc = zmq_close(zmq_client_socket);
  ZEROMQ_ASSERT(rc == 0);

  return 0;
}
