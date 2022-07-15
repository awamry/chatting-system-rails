<div id="top"></div>

<!-- PROJECT LOGO -->
<br />
<div align="center">
<h3 align="center">Chatting System</h3>

  <p align="center">
    A highly scalable chatting system developed with low latency and high throughput in mind that allows creation of applications where each
    application gets a specified token that gets generated from the system. This token is the application identifier that allows
    creation of chats which returns the chat number that has been created under the specified application. By combining the application 
    token with the chat number, you will be able to send messages to other members that are sharing the same chat with you
    <br />
    <br />
    <br />
  </p>
</div>



<!-- TABLE OF CONTENTS -->
<details>
  <summary>Table of Contents</summary>
  <ol>
    <li>
      <a href="#about-the-project">About The Project</a>
      <ul>
        <li><a href="#technology-stack">Built With</a></li>
      </ul>
    </li>
    <li>
      <a href="#getting-started">Getting Started</a>
      <ul>
        <li><a href="#prerequisites">Prerequisites</a></li>
        <li><a href="#installation">Installation</a></li>
      </ul>
    </li>
    <li><a href="#usage">Usage</a></li>
  </ol>
</details>



<!-- ABOUT THE PROJECT -->

## About The Project

This system was built with a mindset that demanded the ability to handle as many concurrent requests as possible
while promising very high throughput and low latency to clients interacting with it.

To achieve these requirements, the creation of an Application is very straightforward, just provide the name of your
application
and the system will respond back to you with your application token. Applications are persisted immediately to the
database.

<b>For chats and messages creation</b>, it was required to avoid writing to MySQL directly while serving the client's request,
but at the same time we need to respond to the client with the newly created chat's or message's number, which indeed, should be
unique for all
chats under the same application.

To achieve this requirement, Redis has been used as a datastore for chat/message numbers for each application/chat, so  
when POST [/chats, /messages] API endpoint is called, we rely on Redis' superior speed to give us the next
chat's/message's number
of the give application/chat. However, the chat/message has not been actually created and no one communicated
with MySQL to persist it yet.

Here comes the role of RabbitMQ. In our application, we will Publish the newly created chat/message payload to
rabbitMQ. A dedicated set of publishers are responsible to deliver the payload to the needed exchange and to the needed
queue.

Perfect! now the chat has been published and is persisted on RabbitMQ queue, but who is going to consume this chat/message
from the queue and
actually insert it into MySQL? Meet <a href="https://github.com/jondot/sneakers">Sneakers</a>, A fast background
processing framework for Ruby and RabbitMQ which is the optimal solution to our requirement.

Sneakers will run as a background worker that is responsible to pull any new chats/messages that are added to the queue
and persist them to MySQL accordingly.

Now, we have finally persisted the chat/message to the database after a long trip.

<b>For the next requirement</b>, it was required to have chats_count column in Application table, and also
have messages_count column in Chat table. But it was okay for those columns to be eventually consistent
after 1 hour. It is clear that the goal of this requirement is to minimize writing to or querying from MySQL directly
on this columns as they will drastically degrade the performance.

To achieve this requirement, Redis (again) has been used to store chats count for every application
and messages count for every chat. Creation of new applications or chats subsequently increment the chats count
or messages count keys in Redis and not in the database.

Now it is time to let MySQL in-sync with Redis, <a href="https://github.com/mperham/sidekiq">Sidekiq</a>
was the best option to use as it could execute background tasks in simple and efficient way. In order to
execute this Sidekiq task every 1 hour (as per the requirement), <a href="https://github.com/ondrejbartas/sidekiq-cron">
Sidekiq-cron</a>
library has been used to call Sidekiq's job every 1 hour.

Hopefully, every 1 hour the database will be in-sync with redis for chats_count and messages_count columns.

<b>For the last (challenging) requirement</b>, it was required to create an endpoint that will be used for searching
through messages of a specific chat. It was required to support partial matching to the messages' bodies that belong to the specified chat.

To achieve this requirement, ElasticSearch was an optimal fit for this scenario. The requirement was not too clear, so
the API
that has been created will only match if the query is between 3 (inclusive) to 10 characters (inclusive) in length
(this is an index configuration, so it could be changed easily to match a greater range of characters but at the cost of index size)

<br><br><br>
<p align="right">(<a href="#top">back to top</a>)</p>

### Technology Stack

* [![ROR][ROR]][Ror-url]
* [![MySQL][MySQL]][MySQL-url]
* [![Redis][Redis]][Redis-url]
* [![RabbitMQ][RabbitMQ]][RabbitMQ-url]
* [![ElasticSearch][ElasticSearch]][ElasticSearch-url]

<p align="right">(<a href="#top">back to top</a>)</p>



<!-- GETTING STARTED -->

## Getting Started

### Prerequisites

You need to have Docker (along with compose extension inside it) installed on your machine in order to run the whole stack.
* Docker: My docker version that I was working on was <b>Docker version 20.10.17, build 100c701</b>
* Docker compose plugin: I used compose plugin in docker (<b>docker compose</b> not <b>docker-compose) version v2.6.0

### Installation

1. Clone the repository
   ```sh
   git clone https://github.com/awamry/chatting-system-rails.git
   ```
2. cd to the repository
   ```sh
   cd TO_THE_DIRECTORY_OF_THE_REPOSITORY
   ```
3. Run the whole stack using docker compose
    ```sh
   docker compose up --build
   ```

<p align="right">(<a href="#top">back to top</a>)</p>



<!-- USAGE EXAMPLES -->

## Usage Examples

1. Create a new application
   ```bash
    curl --request POST 'http://localhost:3000/applications' \
    --header 'Content-Type: application/json' \
    --data-raw '{"name" :"GitHub App" }' 
   ```
   You will receive a response like this
    ```bash
    { "name":"GitHub App","token":"6bc5bd11-87f8-4796-820e-80e57403ce13" }
    ```
   Make sure to save the value of "token" field as you will need it in all of the upcoming requests
   <br><br>
2. Create a new chat under a specific application
   ```bash
    curl --request POST 'http://localhost:3000/applications/YOUR_APPLICATION_TOKEN/chats'
   ```
   You will receive a response like this
    ```bash
    { "number": 1 }
    ```
   Make sure to save the value of "number" field as you will need it in all of the upcoming requests related to messages
   <br><br>
3. Create a new message under a specific chat number which belongs to a specific application
   ```bash
    curl --request POST 'http://localhost:3000/applications/YOUR_APPLICATION_TOKEN/chats/YOUR_CHAT_NUMBER/messages' \
            --header 'Content-Type: application/json' \
            --data-raw '{
            "body": "Hello GitHub application users in chat number 1"
            }'
   ```
   You will receive a response like this
    ```bash
    {
      "number": 1,
      "body": "Hello GitHub application users in chat number 1"
    }
    ```
   Make sure to save the value of "number" field as it is the chat number and you will need it in all of the upcoming requests related to messages
   <br><br>
4. Create a new message under a specific chat number which belongs to a specific application
   ```bash
    curl --request GET 'http://localhost:3000/applications/YOUR_APPLICATION_TOKEN/chats/YOUR_CHAT_NUMBER/body/search?q=git'
   ```
   Please note that `q` is the query parameter that its value will be used to search for messages that partially contain this value.
   in this example we are searching for messages that contain the keyword 'git' (yes, the search that has been implemented is case-insensitive)

   You will receive a response like this
    ```bash
    [
     {
        "number": 1,
        "body": "Hello GitHub application users in chat number 1"
     }
   ]
    ```

<p align="right">(<a href="#top">back to top</a>)</p>





<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->



[product-screenshot]: images/screenshot.png

[ROR]: https://img.shields.io/badge/rails-%23CC0000.svg?style=for-the-badge&logo=ruby-on-rails&logoColor=white

[ROR-url]: https://rubyonrails.org/

[MySQL]: https://img.shields.io/badge/mysql-%2300f.svg?style=for-the-badge&logo=mysql&logoColor=white

[MySQL-url]: https://dev.mysql.com/

[Redis]: https://img.shields.io/badge/redis-%23DD0031.svg?style=for-the-badge&logo=redis&logoColor=white

[Redis-url]: https://redis.io/

[RabbitMQ]: https://img.shields.io/badge/Rabbitmq-FF6600?style=for-the-badge&logo=rabbitmq&logoColor=white

[RabbitMQ-url]: https://www.rabbitmq.com/

[ElasticSearch]: https://img.shields.io/badge/-ElasticSearch-005571?style=for-the-badge&logo=elasticsearch

[ElasticSearch-url]: https://www.elastic.co/

[Vue-url]: https://vuejs.org/

[Angular.io]: https://img.shields.io/badge/Angular-DD0031?style=for-the-badge&logo=angular&logoColor=white

[Angular-url]: https://angular.io/

[Svelte.dev]: https://img.shields.io/badge/Svelte-4A4A55?style=for-the-badge&logo=svelte&logoColor=FF3E00

[Svelte-url]: https://svelte.dev/

[Laravel.com]: https://img.shields.io/badge/Laravel-FF2D20?style=for-the-badge&logo=laravel&logoColor=white

[Laravel-url]: https://laravel.com

[Bootstrap.com]: https://img.shields.io/badge/Bootstrap-563D7C?style=for-the-badge&logo=bootstrap&logoColor=white

[Bootstrap-url]: https://getbootstrap.com

[JQuery.com]: https://img.shields.io/badge/jQuery-0769AD?style=for-the-badge&logo=jquery&logoColor=white

[JQuery-url]: https://jquery.com 