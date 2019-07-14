+++
title = "Algebraic Data Types"
[taxonomies]
categories = ["Functional Programming"]
+++

This post starts a description of algebraic data types. For me, these have completely replaced
my mental machinery for designing and reasoning about programs. They also provide a way to explore
ideas and guide my programs.

The types described here are monomorphic- they do not have any type parameters. The whole algebraic
structure can be lifted up a level to combine structures that have type parameters, which I hope to
get to in another post.
Hopefully I can get into even more fun through how this lifts into Functors, or to the Howard
Curry Isomorphism and how the type systems we look at are systems of logic.


My main exposure to functional programming languages is Haskell, and the Elm I'm been exploring recently.
The descriptions given here are a mix of Haskell, type theory, set theory, and natural language.


We will start our journey with the primitive types that make up the floor of the tower of types that
can be defined by taking the sums, products, and exponents of algebraic types. We will work our way
up to the operators themselves and the motivation for their names, as well as some uses for each.



Primitive Types
===============
A type system will have a series of primitive types for things like integers, positive numbers, encodings
of the reals, characters, and booleans.



Enumerations
============
They can also have a way to describe types with a finite number of elements, indexed by natural
numbers (enumerations). Enumerations end up being like having natural number in the type system, as we
will see later.

Enumerations provide some motivation for the name "algebraic" data types. They consist of a set of
symbols, often identified with a integer.

In C this would look like:
    enum MSG_ID_ENUM;
    {
      MSG_ID_SAVE,
      MSG_ID_UPDATE,
      MSG_ID_PRINT
    };

and in Haskell
    data MsgId = MsgIdSave | MsgIdUpdate | MsgIdPrint deriving (Enum)

An enumeration has a finite number of elements, and acts as a natural number within the type system.
The number that an enumeration cooresponds to is the number of elements that it has.

We will see later that the sums, products, and exponents of algebraic data types act like sums, product,
and exponents on the number of elements in an enumeration.



Products
========
Product types or something like them are common, and come up immediately when modeling essentially
any information. The values of this type are, for example "(3, "test", True)".
When reading this value, we have a 3, and the string "test", and the boolean value True.
In C and its family of languages they are called structs.

In Haskell the product type is written "(a,b)". Other product types can be defined, such as
"data Prod a b = Prod a b", which are isomorphic to "(a,b)".


Algebra
--------
As an initial motivation for considering these types "products" rather than "sums" or something else is to
consider what happens when taking the product of enumerations- the number of elements in the product
of two enumerations is the product of the number of elements of each.


This isn't the only reason that these are products. When we get to sum types, we will see that products
distribute over sums, just as they would in elementary algrebra.

Logic
-----
Products sequence data- they are like the word (and logical connective) "and".
The product of an integer, a string, and a boolean might be written "integer x string x boolean"
or "(integer, string, boolean)".  



Unit
=====
Algebra
The unit of multiplication is 1, and the unit of the product of types is (), sometimes called Unit.
It is a type with a single inhabitant, in Haskell this element is also called (). 

This is the unit of product types for the same reason that the cartesian product of a set with
a set containing one element is isomorphic to the original set- all elements are paired with the
same value so it adds nothing to the structure. In symbols ax() ~ a.


A fun fact about the unit type is that the type of functions from unit into a type 'a' is isomorphic to
a- in symbols this is the fact that () -> a ~ a. This is because each function can map the () into a
single element. Going the other way, each function can be mapped to an element of the type 'a' by
simply applying the function to the () value.


This ignores some details about extra bottom elements having to do with non-terminating computations.


Logic
-----
Product types coorespond to the And connective in logic. The unit of And is True- 'True And p' has the
proof value of p, the same as 'p And True'. 



Sums
====
Sum types are more rare in programming languages then product types, but they are hugely useful.
When designing a game, or the communication of two systems, or the telemetry reported by
an embedded system, one often needs to provide one of several possible options perhaps
with additional data. 

In C, one might right:
    typedef union
    {
       SaveData saveData;
       UpdateData updateData;
       PrintData printData;
    } Payload;

    enum MSG_ID_ENUM;
    {
      MSG_ID_SAVE,
      MSG_ID_UPDATE,
      MSG_ID_PRINT
    };

    typedef struct
    {
      MSG_ID_ENUM msgID;
      Payload payload;
    } Message;

The enumeration is required to distinguish between the possible values for the message payload.
The union type itself is like a union in set theory- the number of elements in a union type is the number
of elements in each of the two types, minus the shared elements. Sum types are more like a disjoint union-
the tag prevents elements that would otherwise be the same from being equal. The whole concept of
elements of sets being equal is a little tricky due to the lack of unions and the complexity of equality
in type theory. Just note that there is some subtly here.


In Haskell this might look like:
    data Payload = PayloadSave SaveData
                 | PayloadUpdate UpdateData
                 | PayloadPrint PrintData

Depending on the situation, the data within the SaveData, UpdateData, and PrintData types can
be placed within the PayloadSave, PayloadUpdate, and PayloadPrint constructors. The equalivant in C
would be to use anonymous structs.

The values of this type can contain any of the three constructors. This allows multiple types of messages
to be sent and received in a type same way. 


If there are only two types to sum, we could use:
    type Payload = Either SaveData UpdateData
but this gets cumbersome with more types:
    type Payload = Either SaveData (Either UpdateData PrintData)

Algebra
-------
Now that we have products and sums, we can see how they interact. In Haskell:
    type T1 = (a, Either b c)
is isomorphic to:
    type T2 = (Either a b, Either a c)
Both types must have a value of type 'a', and both will have either a value of type 'b' or 'c'.
Their values are different, but there is a function from T1 to T2 and back which compose in both
directions to produce the identity function.

Logic
-----
The connection between algebra and logic for sums is that sum types are like the word (and logical
connective). Given a type "integer + boolean", written in Haskell as "Either Int Bool",
its values are "Left 3" or "Right True".

The introduction form for an Or operator requires either a value of type 'a' or a value of type 'b'.
If 'a' is true, then we can make the statment 'a Or b', and if 'b is true, we can still make the
statement 'a Or b'. I'm ignoring the difference between a true statement in classical logic,
and a proof of a type by an element of it.

The elimination form for Or requires a way to prove a statement/type 'c' using an 'a', or a way to
prove a type 'c' using a 'b'. In symbols, '(a -> c) -> (b -> c) -> (a Or b) -> c'. The statement
'c' is true if 'a Or b' is true and there is a way to prove c regardless of which of 'a' or 'b' is
true.



Void
====
The unit of addition is 0, and the unit of sum types is Void. This type has no values (ignoring bottom
if it exists, as usual).
  
This is why it is the unit of sum types- it is a path that cannot be taken.
Taking the sum with the Void type means that one side of the sum has no values, so it is like tagging
all values of the other type with the same tag. This doesn't change the structure of the type in
any meaningful way.


Logic
-----
Sums coorespond to the Or connective in logic. The unit of Or is False, as 'False Or p' has the truth
value of p, which is the same as 'p Or False'. This is appropriate, as there should be no way to 
construct a valid proof which is false in a system of logic. The connection to constructive logic
here makes the connection even more interesting- this is no surprise as the type theory of a language
is a system of logic.


Exponents
=========
Exponential types also come up all the time, and the presence or absense of these are, for me,
one of the biggest distinguishing factors between programming languages. 

Suprisingly, exponentials coorespond to function types such as "a -> b", pronouced "a arrow b". This is
the type of functions from a type 'a' to a type 'b'.


Algebra
-------
To continue the motivation with enumerations: the space of functions from an enumeration with n elements
to an enumeration with m elements has m^n elements (m raised to the n). This is because each function
must map each element of the first enumeration to an element of the second. This means each function
makes n choices, each of which can be from one of m values.


Logic
-----
The cooresponding operator in logic is implication. The introduction and elimination forms in lambda
calculus describe how to use this operator.


Haskell
-------
I can't help but mention how well functions and function types are supported in Haskell. They are
available in other languages, but not in the same way. Haskells functions are a powerful tool,
a way to abstract and combine computations.



