from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import uuid

app = FastAPI(docs_url=None)

class User(BaseModel):
    username: str
    token: str

class Message(BaseModel):
    message: str
    token: str

# список зарегистрированных пользователей
users = []

# список сообщений
messages = []

# функция для поиска пользователя по токену
def find_user(token):
    for user in users:
        if user.token == token:
            return user
    return None

# роут для логина
@app.post('/login')
def login(username: str):
    token = str(uuid.uuid4()) # генерируем уникальный токен
    user = User(username=username, token=token)
    users.append(user)
    return {'token': token}

# роут для логаута
@app.delete('/logout')
def logout(token: str):
    user = find_user(token)
    if user:
        users.remove(user)
        return 'User removed from chat'
    else:
        raise HTTPException(status_code=404, detail='User not found')

# роут для получения списка сообщений
@app.get('/message/list')
def get_messages(token: str):
    user = find_user(token)
    if user:
        # получаем последние 50 сообщений
        last_messages = messages[-50:]
        return last_messages
    else:
        raise HTTPException(status_code=404, detail='User not found')

# роут для отправки сообщения
@app.post('/message')
def post_message(message: Message):
    user = find_user(message.token)
    if user:
        message_id = str(uuid.uuid4()) # генерируем уникальный идентификатор для сообщения
        messages.append({'user': user.username, 'message': message.message, 'id': message_id})
        return {'id': message_id}
    else:
        raise HTTPException(status_code=404, detail='User not found')

# роут для получения списка залогиненных пользователей
@app.get('/user/list')
def get_users(token: str):
    user = find_user(token)
    if user:
        user_list = [{'username': u.username, 'token': u.token} for u in users]
        return user_list
    else:
        raise HTTPException(status_code=404, detail='User not found')
