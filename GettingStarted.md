# 시작하기

## 소개

**Dex(Data Exchanger)** - 데이터 서비스(Data as a Service)를 위한 데이터 주도 개발(Data-driven Programming) 프레임워크로서 데이터를 좀 더 쉽고 빠르게 조작하고 이를 인터넷 상에서 서비스할 수 있게 한다.

데이터를 서비스로서 제공하기 위해서는 계획-개발-서비스 전반에 걸쳐 데이터 중심적 사고(data-driven thinking)와 이를 구현해줄 수 있는 프로그래밍 도구, 풍부한 라이브러리, 안정적 서비스 환경이 필요하다. 

본 프로젝트는 Erlang/OTP 기반 Elixir 언어의 단순함과 고생산성, 병행성, 고장허용성 등 다양한 특장점들을 활용하였으며 대량 트래픽과 데이터를 수용할 수 있도록 수평적 확장이 용이하게 설계되었다. 또한 새로운 기능들을 쉽게 추가하고 외부 제품이나 서비스들을 연동할 수 있는 유연한 메커니즘을 제공한다.

> **Note:**  Elixir는 얼랭 가상 머신(BEAM) 위에서 동작하는 함수형, 동시성 프로그래밍 언어이다. 엘릭서(Elixir)는 얼랭에서 구현된 분산, 장애 내구성, 실시간, 무정지 어플리케이션과 같은 특징 뿐 아니라 프로토콜을 통해 매크로와 다형성을 지원한다. - 위키백과

**DexyML(Markup Language)** - XML 기반 스크립트로서 데이터 중심 서비스를 개발하는데 최적화되었다. 구조적 프로그래밍 및 데이터 협업이 가능하고 자바스크립트 등 타 컴퓨터 언어를 임베딩 할 수 있어서 기능을 확장하는데 용이하게 하였다. 작성된 스크립트는 Elixir 언어로 변환된 후 Erlang 바이트 코드로 컴파일 되어 실행되므로 인터프리팅 방식에 비해 매우 빠르게 동작한다.

지금부터 DexyML을 이용한 데이터 앱 제작 방법을 알아보자. 다음은 작동 가능한 최소한의 데이터 앱이다.
```
<data/>
```
`dex> nil`

굉장히 심플하지 않은가? 컴퓨터 언어를 처음 배울 때 "Hello World" 를 출력해본 경험이 있을 것이다. 스크립트를 통해 표현하면 다음과 같다.
```
1	<data>
2	  "Hello World"
3	</data>
```
`dex> "Hello World"`

모든 앱은 `<data>`로 시작하여 내용을 작성하고 `</data>`로 끝낸다. 위 예제에서는  `<data/>` 내에 아무런 내용이 없으므로 특별한 기능을 수행하지 않고 단순 문자열만 출력한다.

**Pipescript** - DexyML은 데이터 처리에 필요한 기능들(functions)을 사용하기 위해 유닉스의 파이프라인( | ) 형태의 스크립트를 제공함으로써 문법을 단순화시켰다. 파이프스크립트의 기본 문법과 사용법을 알아보자.

	Syntax : | [함수명] [인자값, ..] [옵션값, ..]

	- 함수명 : 내장(built-in)함수, 지역(unser-defined)함수, 라이브러리
	- 인자값 : 함수 호출에 필요한 값들(arguments)로서 
	- 옶션값 : 선택적 매개변수로서 'name: value' 형식으로 사용

위 "Hello World" 예제는 사실 다음과 같은 스크립트를 축약한 것이다.
```
1	<data>
2	  | set "Hello World"
3	</data>
```
`dex> "Hello World"`

위 예제에서 `set`은 메모리에 어떠한 값을 저장하는 내장함수이며 인자값으로는 "Hello World" 문자열을 전달하였다. 파이프스크립트는 특정 변수를 지정하지 않으면 기본적으로 `data`라는 변수를 참조하므로 여기에 "Hello World" 문자열을 저장하게 된다.  해당 라인을 `| set data: "Hello World"`와 같이 작성해도 결과는 동일하다.

여러 변수에 값을 저장하고 싶다면 다음과 같이 작성할 수 있다.

```
1	<data>
2	  | set name: "foo"
3	  | set age: 10
4	  | set friends: ["bar", "baz"]
5	</data>
```
`dex> nil`

위 스크립트를 좀 더 단순하게 표현하면 다음과 같다.
```
1	<data>
2	  | set name: "foo", age: 10, friends: ["bar", "baz"]
3	</data>
```
`dex> nil`

위 예제는 `name`, `age`, `friends` 라는 변수 3개를 사용하여 값을 저장하였다. 모든 값들은 메모리 상에 보관되며 스크립트가 종료되는 시점에 사라지게 된다. 정확히 얘기하면 Erlang VM(virtual machine)의 Garbage Collector에 의해 정리된다. 그런데 스크립트의 결과 값이 이상하지 않은가? 분명히 세 개의 변수에 값을 넣었는데 다 어디로 사라져버렸다.

앱이 종료되면 최종적 `data` 변수 값을 참조하여 출력하게 된다. 따라서 위 예제에서는 `data`에 아무런 값도 저장하지 않았으므로 `nil`이 될 수밖에 없는 것이다.  다음 예제를 보자.
```
1	<data>
2	  | set "foo" age: 10, friends: ["bar", "baz"]
3	</data>
```
`dex> "foo"`

위 예제에서는 `set` 함수의 인자 값으로 전달된 문자열 "foo"가 변수 `data`에 입력되었다. 따라서 선택적 변수로 전달된 나머지 값들은 출력 값에서 제외되고 `data` 변수의 값만 출력된다. 그러면 `age' 변수의 값을 출력하려면 어떻게 해야 할까? 위 스크립트를 조금 손을 보자.
```
1	<data>
2	  | set "foo" age: 10, friends: ["bar", "baz"]
3	  | set age
4	</data>
```
`dex> 10`

라인 `2`에서 `age` 변수에 `10`을 저장하고 라인`3`에서 `set` 함수에 `age` 변수의 값을 전달했기 때문에 `data` 변수에 `10`이 저장된다. 라인`3`을 다시 표현하면 다음과 같다.

`| set data: age`

파이프스크립트의 장점은 데이터 처리 과정을 단순하면서도 보기 쉽게 표현할 수 있다는 것이다. 다음 예제를 통해 문자열을 분리하고 카운트하는 앱을 작성해보자.
```
1	<data>
2	  | set "a, b, c, d, e"
3	  | split ","
4	  | count
5	</data>
```
`dex> 5`

위 예제에서 볼 수 있듯이 파이프라인 형태의 스크립트는 데이터 처리를 단순 명료하게 기술할 수 있어서 눈으로 보고 머리로 해석하는데 피로감이 덜하다.

## 기본 자료형

Dex는 일반적 컴퓨터 언어들과 마찬가지로 기본적인 자료 형태들을 제공하며 Elixir 언어의 타입들을 대부분 그대로 따른다.

### Number

숫자는 정수와 부동소수점(floating point) 방식의 실수를 지원한다. Float 타입은 64비트 배정도(double precision)로 표현된다.

```
1	<data>
2	  | set 10    | is_number    | assert true
3	  | set 10    | is_integer   | assert true
4	  | set 1.0   | is_float     | assert true
5	</data>
```
`dex> true`

`is_[type]` 함수는 `data` 변수에 저장된 값의 자료형(data type)을 반환한다.
`assert [expression]` 구문은 `expression`이 `참(true)`인지 확인하고 만약 `거짓(false)`이면 예외(exception)을 발생시킨다.

이번엔 간단한 산수 능력을 시험해보자.
```
1	<data>
2	  | set 1 + 2   | assert 3
3	  | set 5 * 5   | assert 25
4	  | set 10 / 2  | assert 5.0
5	</data>
```
`dex> 5.0`

위 스크립트에서 라인`4`의 `10 / 2`의 계산 결과가 `5`가 아닌 `5.0`가 나왔다. Elixir 에서 `/` 계산 결과는 항상 `float` 타입의 값을 반환한다. 만약 정수 몫(integer quotient)과 나머지(remainder)를 원한다면 `div`와 `rem`을 사용하면 된다.

```
1	<data>
2	  | set 5 / 2   | assert 2.5
3	  | div 5 / 2	| assert 2
4	  | rem 5 / 2   | assert 1
5	</data>
```

### String
문자열은 내부적으로 Erlang 바이너리 문자열(bitstring) 타입을 따르며 Elixir에서 제공하는 문자배열(character list)은 지원하지 않는다.

```
1	<data>
2	  | "Hello"   | is_string
3	</data>
```
`dex> true`
```
1	<data>
2	  | set "Hello " <> "World!"
4	</data>
```
`dex> "Hello World!"`

문자열 간의 연결은 Elixir 에서 제공하는 오퍼레이터를 동일하게 사용한다.
```
1	<data>
2	  | set name: "Foo"
2	  | set "Hello, " <> name
4	</data>
```
`dex> "Hello, Foo"`

### List

데이터의 배열로서 

### Tuple
튜플

### Map
맵


__TODO__

## 조건문

### if else
### case

## 반복문

### for

## 함수


## 어노테이션

### Global Annotations

#### id
#### title
#### appdoc
#### access
#### tags
#### use
#### disabled
#### set

### Function Annotations

#### public
#### private
#### lang
#### cdata
#### doc
#### noparse

