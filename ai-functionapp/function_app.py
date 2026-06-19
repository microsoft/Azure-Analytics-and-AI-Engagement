import azure.functions as func
import logging
import time
import json
import random
from src.hardcodedReplies import OnlyOneIterationAnswer
from src.hardcodedReplies import FirstIteration_v1, FirstIteration_v2, FirstIteration_v3, SecondIteration_v1, SecondIteration_v2, SecondIteration_v3, ThirdIteration_v1, ThirdIteration_v2, ThirdIteration_v3, FourthIteration_v1, FourthIteration_v2, FourthIteration_v3,greetings,InstoreFirstIteration_v1,InstoreFirstIteration_v2,InstoreFirstIteration_v3,FifthIteration_v1,FifthIteration_v2,FifthIteration_v3
app = func.FunctionApp(http_auth_level=func.AuthLevel.ANONYMOUS)

@app.route(route="hardcode_chat_function_1a")
def hardcode_chat_function_1a(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('Python HTTP trigger function processed a request.')

    query = req.params.get('query')
    if not query:
        try:
            req_body = req.get_json()
        except ValueError:
            pass
        else:
            query = req_body.get('query')

    image = req.params.get('image')
    if not image:
        try:
            req_body = req.get_json()
        except ValueError:
            pass
        else:
            image = req_body.get('image')
    if image is None:
        image = False

    time.sleep(3)
    if query == "How many gallons of paint do I need to buy to paint my living room? Its about 12 ft by 15 ft." or query == "How much paint will I need to cover a 15x15 ft living room room?" or query == "Can you help me figure out the paint needed for a 15 x15 living space?":
        Answer = OnlyOneIterationAnswer
        return func.HttpResponse(
            json.dumps(Answer),
            mimetype="application/json",
            status_code=200
        )
    
    if query == "Hi, I’m looking to buy some paint, but I’m not sure about the shade or how much I’ll need yet." or query == "Hello, I need some help with paint—I haven’t picked out a color or figured out the number of gallons just yet." or query == "I’d like to get some paint, but I’m still deciding on the color and the amount I’ll need.":
        Answer = random.choice([FirstIteration_v1, FirstIteration_v2, FirstIteration_v3])
        return func.HttpResponse(
            json.dumps(Answer),
            mimetype="application/json",
            status_code=200
        )
    
    if query == "Hi. I want to paint my living room, but I'm not sure what shade I want or how much paint I'll need." or query == "Hello, I need some help with paint for my living room. I haven’t picked out a color or figured out how many gallons I'll need yet." or query == "I’d like to get some paint for my living room. Can you send me some color options and tell me how much paint I'll need?":
        Answer = random.choice([FirstIteration_v1, FirstIteration_v2, FirstIteration_v3])
        return func.HttpResponse(
            json.dumps(Answer),
            mimetype="application/json",
            status_code=200
        )
    
    if query == "I dont have a photo, but its a small living room with a lot of light." or query == "I cannot share a photo, but I can describe the room, its a studio apartment with a lot of light." or image == True:
        Answer = random.choice([SecondIteration_v1, SecondIteration_v2, SecondIteration_v3])
        return func.HttpResponse(
            json.dumps(Answer),
            mimetype="application/json",
            status_code=200
        )
    
    if query == "The room is 11 feet by 14 feet." or query == "Its dimensions are 12 ft x 14 ft." or query == "The size of the room is 13 by 15 feet.":
        Answer = random.choice([ThirdIteration_v1, ThirdIteration_v2, ThirdIteration_v3])
        return func.HttpResponse(
            json.dumps(Answer),
            mimetype="application/json",
            status_code=200
        )
    
    if (
    query == "Hi" or query == "Hello" or query == "Hey" or query == "Hi there" or query == "Hello there" or query == "Hey there" or query == "Hiya" or query == "Howdy" or query == "Greetings" or query == "Salutations" or query == "What’s up?" or query == "How’s it going?" or query == "What’s new?" or query == "How are you?" or query == "How have you been?" or query == "What’s happening?" or query == "What’s good?" or query == "What’s cooking?" or query == "What’s the word?"):
        Answer = greetings
        return func.HttpResponse(
            json.dumps(Answer),
            mimetype="application/json",
            status_code=200
        )
    
    if query == "Thanks so much, Cora! I found the perfect shades and have added them to my cart." or query == "Appreciate your help, Cora! I’ve selected my favorite shades and just placed them in my cart." or query == "Thank you, Cora! I narrowed it down and the shades I wanted are now in my cart.":
        Answer = random.choice([FourthIteration_v1, FourthIteration_v2, FourthIteration_v3])
        return func.HttpResponse(
            json.dumps(Answer),
            mimetype="application/json",
            status_code=200
        )
    
    
    if query == "Can you show me some other paint sprayers?" or query == "Give me alternative paint sprayers" or query == "Do you have different models of paint sprayers?":
        Answer = random.choice([InstoreFirstIteration_v1,InstoreFirstIteration_v2,InstoreFirstIteration_v3])
        return func.HttpResponse(
            json.dumps(Answer),
            mimetype="application/json",
            status_code=200
        )
    
    if query == "Do you have any accessories for painting?"or query== "Can you show me tools that go with paint?" or query== "What should I get along with the paint sprayer?":
        Answer = random.choice([FifthIteration_v1,FifthIteration_v2,FifthIteration_v3])
        return func.HttpResponse(
            json.dumps(Answer),
            mimetype="application/json",
            status_code=200
        )