import azure.functions as func

from sandbox_mcp_server import mcp

_mcp_app = mcp.streamable_http_app()

_MCP_ACCEPT = b"application/json, text/event-stream"


async def mcp_asgi_app(scope, receive, send):
    """MCP streamable-HTTP app adapted to the Azure Functions host.

    GET: MCP clients (including the Foundry agent runtime) open a GET event
    stream for server-initiated messages. This stateless server sends none, and
    the Functions host buffers a response until it completes, so an open stream
    would never return and the client's initialization would time out. GET is
    answered with an event stream that carries no messages and ends immediately.

    POST: the MCP library reads only the first Accept header and requires it to
    list both application/json and text/event-stream; any other form is
    normalized to that single value.
    """
    if scope["type"] == "http" and scope["method"] == "GET":
        await send({
            "type": "http.response.start",
            "status": 200,
            "headers": [(b"content-type", b"text/event-stream"), (b"cache-control", b"no-cache")],
        })
        await send({"type": "http.response.body", "body": b": no server-initiated messages\n\n"})
        return

    if scope["type"] == "http" and scope["method"] == "POST":
        headers = [(k, v) for k, v in (scope.get("headers") or []) if k.lower() != b"accept"]
        scope = dict(scope, headers=headers + [(b"accept", _MCP_ACCEPT)])

    await _mcp_app(scope, receive, send)


# Building the ASGI app only sets up FastMCP routing; the sandbox client,
# credential and network connections are created on the first tool call
# (see sandbox_mcp_server.py), so the host can always index this app.
app = func.AsgiFunctionApp(
    app=mcp_asgi_app,
    http_auth_level=func.AuthLevel.FUNCTION,
)