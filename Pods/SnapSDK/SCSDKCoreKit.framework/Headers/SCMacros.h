//
//  SCMacros.h
//  SCSDKCoreKit
//
//  Created by Xiaomu Wu on 10/22/14.
//  Copyright (c) 2014 Snapchat, Inc. All rights reserved.
//

#ifndef Snapchat_SCMacros_h
#define Snapchat_SCMacros_h

/*
 * Prevents the C++ compiler from mangling C function names.
 */
#ifdef __cplusplus
#define SC_EXTERN_C_BEGIN extern "C" {
#define SC_EXTERN_C_END }
#else
#define SC_EXTERN_C_BEGIN
#define SC_EXTERN_C_END
#endif

/*
 * Calculates the number of elements in a C array.
 */
#define SC_ARRAY_COUNT(x) sizeof(x) / sizeof(x[0])

/*
 * Safeguard against inserting nil into a collection type
 */
#define NSNULL_IF_NIL(x) (x ?: [NSNull null])

/*
 * Converts a symbol into a C / Obj-C string.
 */
#define SC_C_STRINGIFY(str) #str
#define SC_OBJC_STRINGIFY(str) @ #str
/*
 * Expands and converts a macro into a C / Obj-C string.
 */
#define SC_MACRO_C_STRINGIFY(str) SC_C_STRINGIFY(str)
#define SC_MACRO_OBJC_STRINGIFY(str) @SC_C_STRINGIFY(str)

/*
 * Forces the a function to always be inlined if possible. For example, it can't inline a function imported from a
 * header, where the function's implementation is not in that header.
 * In general, prefer inline over this if the goal is to make the function call faster, and only use this in special
 * cases. For example, we use this in SCAppEnvironment to ensure dead code stripping.
 */
#define SC_ALWAYS_INLINE __inline__ __attribute__((__always_inline__))

/*
 * SCStringLiteral is useful for referencing string literals in c structs.
 */
#if __has_feature(objc_arc)
#define SCStringLiteral __unsafe_unretained NSString *
#else
#define SCStringLiteral NSString *
#endif

#define SC_DEFINE_LAZY_ASSOC_OBJ(type, getter)                                                                         \
-(type *)getter                                                                                                    \
{                                                                                                                  \
const void *key = @selector(getter);                                                                           \
type *obj = objc_getAssociatedObject(self, key);                                                               \
if (!obj) {                                                                                                    \
obj = [type new];                                                                                          \
objc_setAssociatedObject(self, key, obj, OBJC_ASSOCIATION_RETAIN_NONATOMIC);                               \
}                                                                                                              \
return obj;                                                                                                    \
}

/*
 * Combines two hashes using a bitwise rotation in addition to bitwise xor.
 */
#define SC_NSUINT_BIT (CHAR_BIT * sizeof(NSUInteger))
#define SC_NSUINT_ROTATE(val, howmuch)                                                                                 \
((((NSUInteger)val) << howmuch) | (((NSUInteger)val) >> (SC_NSUINT_BIT - howmuch)))
#define SC_COMBINE_HASHES(h1, h2) (SC_NSUINT_ROTATE(h1, SC_NSUINT_BIT / 2) ^ h2)

/*
 * Follows the idea of the `guard` statement in Swift.
 * Early exits if a condition is not met.
 */
#define SC_GUARD(condition)                                                                                            \
if (condition) {                                                                                                   \
}
#define SC_GUARD_ELSE_RUN_AND_RETURN_VALUE(condition, statement, value)                                                \
SC_GUARD(condition) else                                                                                           \
{                                                                                                                  \
statement;                                                                                                     \
return value;                                                                                                  \
}
#define SC_GUARD_ELSE_RUN_AND_RETURN(condition, statement) SC_GUARD_ELSE_RUN_AND_RETURN_VALUE(condition, statement, )
#define SC_GUARD_ELSE_RETURN_VALUE(condition, value) SC_GUARD_ELSE_RUN_AND_RETURN_VALUE(condition, , value)
#define SC_GUARD_ELSE_RETURN(condition) SC_GUARD_ELSE_RUN_AND_RETURN_VALUE(condition, , )

/**
 * Clamps value between min and max.
 */
#define SC_CLAMP(v, min, max) MIN(max, MAX(min, v))

/**
 * Returns A and B concatenated after full macro expansion.
 */
#define metamacro_concat_(A, B) A##B
#define metamacro_concat(A, B) metamacro_concat_(A, B)

/**
 * Returns the first argument given. At least one argument must be provided.
 *
 * This is useful when implementing a variadic macro, where you may have only
 * one variadic argument, but no way to retrieve it (for example, because \c ...
 * always needs to match at least one argument).
 *
 * @code
 #define varmacro(...) \
 metamacro_head(__VA_ARGS__)
 * @endcode
 */
#define metamacro_head_(FIRST, ...) FIRST
#define metamacro_head(...) metamacro_head_(__VA_ARGS__, 0)

// metamacro_at expansions
#define metamacro_at0(...) metamacro_head(__VA_ARGS__)
#define metamacro_at1(_0, ...) metamacro_head(__VA_ARGS__)
#define metamacro_at2(_0, _1, ...) metamacro_head(__VA_ARGS__)
#define metamacro_at3(_0, _1, _2, ...) metamacro_head(__VA_ARGS__)
#define metamacro_at4(_0, _1, _2, _3, ...) metamacro_head(__VA_ARGS__)
#define metamacro_at5(_0, _1, _2, _3, _4, ...) metamacro_head(__VA_ARGS__)
#define metamacro_at6(_0, _1, _2, _3, _4, _5, ...) metamacro_head(__VA_ARGS__)
#define metamacro_at7(_0, _1, _2, _3, _4, _5, _6, ...) metamacro_head(__VA_ARGS__)
#define metamacro_at8(_0, _1, _2, _3, _4, _5, _6, _7, ...) metamacro_head(__VA_ARGS__)
#define metamacro_at9(_0, _1, _2, _3, _4, _5, _6, _7, _8, ...) metamacro_head(__VA_ARGS__)
#define metamacro_at10(_0, _1, _2, _3, _4, _5, _6, _7, _8, _9, ...) metamacro_head(__VA_ARGS__)
#define metamacro_at11(_0, _1, _2, _3, _4, _5, _6, _7, _8, _9, _10, ...) metamacro_head(__VA_ARGS__)
#define metamacro_at12(_0, _1, _2, _3, _4, _5, _6, _7, _8, _9, _10, _11, ...) metamacro_head(__VA_ARGS__)
#define metamacro_at13(_0, _1, _2, _3, _4, _5, _6, _7, _8, _9, _10, _11, _12, ...) metamacro_head(__VA_ARGS__)
#define metamacro_at14(_0, _1, _2, _3, _4, _5, _6, _7, _8, _9, _10, _11, _12, _13, ...) metamacro_head(__VA_ARGS__)
#define metamacro_at15(_0, _1, _2, _3, _4, _5, _6, _7, _8, _9, _10, _11, _12, _13, _14, ...) metamacro_head(__VA_ARGS__)
#define metamacro_at16(_0, _1, _2, _3, _4, _5, _6, _7, _8, _9, _10, _11, _12, _13, _14, _15, ...)                      \
metamacro_head(__VA_ARGS__)
#define metamacro_at17(_0, _1, _2, _3, _4, _5, _6, _7, _8, _9, _10, _11, _12, _13, _14, _15, _16, ...)                 \
metamacro_head(__VA_ARGS__)
#define metamacro_at18(_0, _1, _2, _3, _4, _5, _6, _7, _8, _9, _10, _11, _12, _13, _14, _15, _16, _17, ...)            \
metamacro_head(__VA_ARGS__)
#define metamacro_at19(_0, _1, _2, _3, _4, _5, _6, _7, _8, _9, _10, _11, _12, _13, _14, _15, _16, _17, _18, ...)       \
metamacro_head(__VA_ARGS__)
#define metamacro_at20(_0, _1, _2, _3, _4, _5, _6, _7, _8, _9, _10, _11, _12, _13, _14, _15, _16, _17, _18, _19, ...)  \
metamacro_head(__VA_ARGS__)

/**
 * Returns the Nth variadic argument (starting from zero). At least
 * N + 1 variadic arguments must be given. N must be between zero and twenty,
 * inclusive.
 */
#define metamacro_at(N, ...) metamacro_concat(metamacro_at, N)(__VA_ARGS__)

/**
 * Returns the number of arguments (up to twenty) provided to the macro. At
 * least one argument must be provided.
 *
 * Inspired by P99: http://p99.gforge.inria.fr
 */
#define metamacro_argcount(...)                                                                                        \
metamacro_at(20, __VA_ARGS__, 20, 19, 18, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1)

#define metamacro_consume_(...)
#define metamacro_expand_(...) __VA_ARGS__

/**
 * Decrements VAL, which must be a number between zero and twenty, inclusive.
 *
 * This is primarily useful when dealing with indexes and counts in
 * metaprogramming.
 */
#define metamacro_dec(VAL) metamacro_at(VAL, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19)

// metamacro_if_eq expansions
#define metamacro_if_eq0(VALUE) metamacro_concat(metamacro_if_eq0_, VALUE)

#define metamacro_if_eq0_0(...) __VA_ARGS__ metamacro_consume_
#define metamacro_if_eq0_1(...) metamacro_expand_
#define metamacro_if_eq0_2(...) metamacro_expand_
#define metamacro_if_eq0_3(...) metamacro_expand_
#define metamacro_if_eq0_4(...) metamacro_expand_
#define metamacro_if_eq0_5(...) metamacro_expand_
#define metamacro_if_eq0_6(...) metamacro_expand_
#define metamacro_if_eq0_7(...) metamacro_expand_
#define metamacro_if_eq0_8(...) metamacro_expand_
#define metamacro_if_eq0_9(...) metamacro_expand_
#define metamacro_if_eq0_10(...) metamacro_expand_
#define metamacro_if_eq0_11(...) metamacro_expand_
#define metamacro_if_eq0_12(...) metamacro_expand_
#define metamacro_if_eq0_13(...) metamacro_expand_
#define metamacro_if_eq0_14(...) metamacro_expand_
#define metamacro_if_eq0_15(...) metamacro_expand_
#define metamacro_if_eq0_16(...) metamacro_expand_
#define metamacro_if_eq0_17(...) metamacro_expand_
#define metamacro_if_eq0_18(...) metamacro_expand_
#define metamacro_if_eq0_19(...) metamacro_expand_
#define metamacro_if_eq0_20(...) metamacro_expand_

#define metamacro_if_eq1(VALUE) metamacro_if_eq0(metamacro_dec(VALUE))
#define metamacro_if_eq2(VALUE) metamacro_if_eq1(metamacro_dec(VALUE))
#define metamacro_if_eq3(VALUE) metamacro_if_eq2(metamacro_dec(VALUE))
#define metamacro_if_eq4(VALUE) metamacro_if_eq3(metamacro_dec(VALUE))
#define metamacro_if_eq5(VALUE) metamacro_if_eq4(metamacro_dec(VALUE))
#define metamacro_if_eq6(VALUE) metamacro_if_eq5(metamacro_dec(VALUE))
#define metamacro_if_eq7(VALUE) metamacro_if_eq6(metamacro_dec(VALUE))
#define metamacro_if_eq8(VALUE) metamacro_if_eq7(metamacro_dec(VALUE))
#define metamacro_if_eq9(VALUE) metamacro_if_eq8(metamacro_dec(VALUE))
#define metamacro_if_eq10(VALUE) metamacro_if_eq9(metamacro_dec(VALUE))
#define metamacro_if_eq11(VALUE) metamacro_if_eq10(metamacro_dec(VALUE))
#define metamacro_if_eq12(VALUE) metamacro_if_eq11(metamacro_dec(VALUE))
#define metamacro_if_eq13(VALUE) metamacro_if_eq12(metamacro_dec(VALUE))
#define metamacro_if_eq14(VALUE) metamacro_if_eq13(metamacro_dec(VALUE))
#define metamacro_if_eq15(VALUE) metamacro_if_eq14(metamacro_dec(VALUE))
#define metamacro_if_eq16(VALUE) metamacro_if_eq15(metamacro_dec(VALUE))
#define metamacro_if_eq17(VALUE) metamacro_if_eq16(metamacro_dec(VALUE))
#define metamacro_if_eq18(VALUE) metamacro_if_eq17(metamacro_dec(VALUE))
#define metamacro_if_eq19(VALUE) metamacro_if_eq18(metamacro_dec(VALUE))
#define metamacro_if_eq20(VALUE) metamacro_if_eq19(metamacro_dec(VALUE))

/**
 * If A is equal to B, the next argument list is expanded; otherwise, the
 * argument list after that is expanded. A and B must be numbers between zero
 * and twenty, inclusive. Additionally, B must be greater than or equal to A.
 *
 * @code
 // expands to true
 metamacro_if_eq(0, 0)(true)(false)
 // expands to false
 metamacro_if_eq(0, 1)(true)(false)
 * @endcode
 *
 * This is primarily useful when dealing with indexes and counts in
 * metaprogramming.
 */
#define metamacro_if_eq(A, B) metamacro_concat(metamacro_if_eq, A)(B)

/**
 * \@keypath allows compile-time verification of key paths. Given a real object
 * receiver and key path:
 *
 * @code
 NSString *UTF8StringPath = @keypath(str.lowercaseString.UTF8String);
 // => @"lowercaseString.UTF8String"
 NSString *versionPath = @keypath(NSObject, version);
 // => @"version"
 NSString *lowercaseStringPath = @keypath(NSString.new, lowercaseString);
 // => @"lowercaseString"
 * @endcode
 *
 * ... the macro returns an \c NSString containing all but the first path
 * component or argument (e.g., @"lowercaseString.UTF8String", @"version").
 *
 * In addition to simply creating a key path, this macro ensures that the key
 * path is valid at compile-time (causing a syntax error if not), and supports
 * refactoring, such that changing the name of the property will also update any
 * uses of \@keypath.
 */
#define keypath(...) metamacro_if_eq(1, metamacro_argcount(__VA_ARGS__))(keypath1(__VA_ARGS__))(keypath2(__VA_ARGS__))

#define keypath1(PATH) (((void)(NO && ((void)PATH, NO)), strchr(#PATH, '.') + 1))

#define keypath2(OBJ, PATH) (((void)(NO && ((void)OBJ.PATH, NO)), #PATH))

#if DEBUG
#define rac_keywordify                                                                                                 \
@autoreleasepool {                                                                                                 \
}
#else
#define rac_keywordify                                                                                                 \
@try {                                                                                                              \
} @catch (...) {                                                                                                   \
}
#endif

/**
 * Creates \c __weak shadow variables for each of the variables provided as
 * arguments, which can later be made strong again with #strongify.
 *
 * This is typically used to weakly reference variables in a block, but then
 * ensure that the variables stay alive during the actual execution of the block
 * (if they were live upon entry).
 *
 * See #strongify for an example of usage.
 */
#define weakify(VAR) rac_keywordify __weak __typeof__(VAR) metamacro_concat(VAR, _weak_) = (VAR);

/**
 * Strongly references each of the variables provided as arguments, which must
 * have previously been passed to #weakify.
 *
 * The strong references created will shadow the original variable names, such
 * that the original names can be used without issue (and a significantly
 * reduced risk of retain cycles) in the current scope.
 *
 * @code
 id foo = [[NSObject alloc] init];
 id bar = [[NSObject alloc] init];
 @weakify(foo, bar);
 // this block will not keep 'foo' or 'bar' alive
 BOOL (^matchesFooOrBar)(id) = ^ BOOL (id obj){
 // but now, upon entry, 'foo' and 'bar' will stay alive until the block has
 // finished executing
 @strongify(foo, bar);
 return [foo isEqual:obj] || [bar isEqual:obj];
 };
 * @endcode
 */
#define strongify(VAR)                                                                                                 \
rac_keywordify _Pragma("clang diagnostic push") _Pragma("clang diagnostic ignored \"-Wshadow\"")                   \
__strong __typeof__(VAR) VAR = metamacro_concat(VAR, _weak_);                                                  \
_Pragma("clang diagnostic pop")

#define strongify_unused(VAR)                                                                                          \
rac_keywordify _Pragma("clang diagnostic push") _Pragma("clang diagnostic ignored \"-Wshadow\"")                   \
__unused __strong __typeof__(VAR) VAR = metamacro_concat(VAR, _weak_);                                         \
_Pragma("clang diagnostic pop")

#endif

