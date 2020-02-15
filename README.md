# iOS News Reader

[![Build Status](https://travis-ci.org/novinfard/iOSNewsReader.svg?branch=master)](https://travis-ci.org/novinfard/iOSNewsReader)

## BDD Specs

### Story: User requests to see the news feed

### Narrative #1

```
As an online reader
I want the app to automatically load the latest news
```

#### Scenarios (Acceptance criteria)

```
Given the user has connectivity
 When the user requests to see the latest news
 Then the app should display the news from remote
  And replace the cache with the new ones
```

### Narrative #2

```
As an offline user
I want the app to show the latest saved version of news
```

#### Scenarios (Acceptance criteria)

```
Given the user doesn't have connectivity
  And there’s a cached version of the news list
  And the cache is less than seven days old
 When the user requests to see the news
 Then the app should display the latest news saved

Given the user doesn't have connectivity
  And there’s a cached version of the news list
  And the cache is seven days old or more
 When the user requests to see the news
 Then the app should display an error message

Given the user doesn't have connectivity
  And the cache is empty
 When the user requests to see the news list
 Then the app should display an error message
```

## Model Specs

### Response Model

| Property      		| Type              |
|-------------------|-------------------|
| `status`      		| `String`			|
| `totalResults`		| `Int`				|
| `news`    			| `[NewsItem]`		|


### NewsItem Model
| Property      		| Type              |
|-------------------|-------------------|
| `id`      			| `UUID`				|
| `source`      		| `Source`			|
| `tags`		 		| `[Tag]` (optional)|
| `author`			| `String`		  	|
| `title`				| `String`		 	|
| `description`		| `String`			|
| `urlToImage`		| `URL` (optional)	|
| `publishedAt `		| `Date`				|
| `content `			| `String`			|


### Tag Model
| Property      		| Type              |
|-------------------|-------------------|
| `id`      			| `UUID`				|
| `name `				| `String`		  	|

### Source Model
| Property      		| Type              |
|-------------------|-------------------|
| `id`      			| `UUID` (optional)	|
| `name `				| `String`		  	|


## Notes
- The `News Reader` is UI/App agnostic. Therefore we have created a macOS framework for it in a separate module. In regard to unit testing, macOS framework is faster as it doesn't have the iOS simulator setup burden.

## Payload Contract
```
GET *url* (TBD)

200 Response

{
    "status": "ok",
    "totalResults": 3,
    "news": [
        {
            "id": 155,
            "source": {
                "id": null,
                "name": "Coindesk.com"
            },
            "tags": [
                {
                    "name": "fintech",
                    "id": 11
                }
            ],
            "author": "Adam B. Levine",
            "title": "Libre Not Libra – Thinking Critically About Facebook’s Blockchain Project",
            "description": "Years of jokes about “FaceCoin” and “ZuckBucks” have finally come to life – sort of.",
            "urlToImage": "https://static.coindesk.com/wp-content/uploads/2016/05/Andreas_M_Antonopoulos_in_Zurich_2016-wiki.jpg",
            "publishedAt": "2020-02-02T16:20:00Z",
            "content": "In Libre Not Libra: Facebooks Blockchain Project, Andreas answers the burning question Has he tried haggis? Just kidding He shares his thoughts on the recently released Libra whitepaper, as part of a permissioned blockchain project spearheaded by Facebook. \r\n… [+1998 chars]"
        },
        {
            "id": 173,
            "source": {
                "id": 97,
                "name": "Innovationexcellence.com"
            },
            "author": "Greg Satell",
            "title": "The Limited Value Of Ideas",
            "description": "There is a line of thinking that says that the world is built on ideas. It was an idea that launched the American Revolution and created a nation. It was an idea that led Albert Einstein to pursue relativity, Linus Pauling to invent a vaccine and for Steve Jo…",
            "urlToImage": null,
            "publishedAt": "2020-02-02T15:00:18Z",
            "content": "by Greg Satell\r\nThere is a line of thinking that says that the world is built on ideas. It was an idea that launched the American Revolution and created a nation. It was an idea that led Albert Einstein to pursue relativity, Linus Pauling to invent a vaccine … [+7391 chars]"
        },
        {
            "id": 190,
            "source": {
                "id": null,
                "name": "Bitcoinist.com"
            },
            "tags": [
                {
                    "name": "fintech",
                    "id": 11
                },
                {
                    "name": "crypto",
                    "id": 34
                }
            ],
            "author": "Christine Vasileva",
            "title": "Crypto Weekend Gains: ETH, ADA, XRP Pump on Sunday",
            "description": "Bitcoin (BTC) momentum has stalled this weekend but a selection of other crypto-assets are showing promising gains today. Namely XRP (XRP), Ethereum (ETH) and Cardano (ADA). ETH Regained Higher Range, Shoots for $200 Ethereum (ETH) quickly regained its $180 r…",
            "url": "https://bitcoinist.com/crypto-weekend-gains-eth-ada-xrp-pump-on-sunday/",
            "urlToImage": "https://bitcoinist.com/wp-content/uploads/2019/12/shutterstock_1050589055-1920x1200.jpg",
            "publishedAt": "2020-02-02T15:00:12Z",
            "content": "Bitcoin (BTC) momentum has stalled this weekend but a selection of other crypto-assets are showing promising gains today. Namely XRP (XRP), Ethereum (ETH) and Cardano (ADA).\r\nETH Regained Higher Range, Shoots for $200\r\nEthereum (ETH) quickly regained its $180… [+2673 chars]"
        }
    ]
}
```

## References
- News sample: Edited version of news feed in https://newsapi.org

## Author
Soheil Novinfard - [www.novinfard.com](https://www.novinfard.com)

## License
This project is licensed under the MIT.