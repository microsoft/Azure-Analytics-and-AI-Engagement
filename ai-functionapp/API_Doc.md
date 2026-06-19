# API Documentation

## Paint Assistant Chat API

**Endpoint:**  
`POST https://func-herodemos-hardcoded.azurewebsites.net/api/hardcode_chat_function_1a`

---

### Request

#### Headers

- `Content-Type: application/json`

#### Body

| Field   | Type     | Description                                        |
| ------- | -------- | -------------------------------------------------- |
| query   | string   | The user input or question. Can be empty if not provided. |
| image   | boolean  | Indicates if the user has uploaded an image (`true`) or not (`false`). |

#### Example

```json
// User provides a query, no image uploaded.
{
    "query": "This is a query",
    "image": false
}

// User uploads an image, no text in the query.
{
    "query": "",
    "image": true
}
```

---

### Response

| Field       | Type     | Description                                       |
| ----------- | -------- | ------------------------------------------------- |
| products    | object   | Contains a list of paint shades under "Paint Shades". |
| answer      | string   | Assistant's reply to user's query.                |
| thinking    | string   | Explanation of assistant's reasoning (optional).  |
| suggestions | array    | Suggested user follow-up queries.                 |

#### Example

```json
{
    "products": {
        "Paint Shades": [
            {
                "id": "PAINT-SHADE-004",
                "name": "Coastal Whisper",
                "type": "Paint Shade",
                "description": "An airy, tranquil blue that evokes relaxing days by the ocean.",
                "imageURL": "https://staidemodev.blob.core.windows.net/hero-demos-hardcoded-chat-images/CoastalWhisper.png",
                "punchLine": "Let the calm of the coast breeze in",
                "price": 39.99
            }
            // ...more paint shades
        ]
    },
    "answer": "Here are a few paint shades to consider for your makeover! Can you share the dimensions of your room? It’ll help me suggest the right quantity and the best tools for the job.",
    "thinking": "The customer wants to paint their room and is looking for both shade suggestions and paint sprayer options. Given the size, a 4 to 5 gallon quantity is recommended. To enhance their experience, presenting stylish color options alongside helpful tools like sprayers supports ease and inspiration.",
    "suggestions": [
        "The room is 12 feet by 15 feet.",
        "Its dimensions are 12 ft x 15 ft.",
        "The size of the room is 12 by 15 feet."
    ]
}
```

---

### Notes

- The `"image"` field in the request should be a boolean (`true`/`false`), not a string.
- The `"query"` must represent what the user actually typed in the webapp; do not send a hardcoded value.
- The `"products"` object may contain multiple paint shades under the `"Paint Shades"` key. Each paint shade includes details such as `id`, `name`, `type`, `description`, `imageURL`, `punchLine`, and `price`.
- The `"answer"` field provides a conversational reply to the user's prompt.
- The `"thinking"` field (optional) describes the assistant's reasoning.
- The `"suggestions"` array helps guide the user with follow-up questions or actions.