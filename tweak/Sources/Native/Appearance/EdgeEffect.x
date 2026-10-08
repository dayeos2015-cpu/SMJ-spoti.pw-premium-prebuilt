#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/message.h>

static char setKey;

// ... dentro del hook/método correspondiente donde ocurre el error:

if ([scrollView respondsToSelector:NSSelectorFromString(@"topEdgeEffect")]) {
    id top = ((id (*)(id, SEL))objc_msgSend)(scrollView, NSSelectorFromString(@"topEdgeEffect"));
    if (top) {
        SEL styleSel = NSSelectorFromString(@"style");
        id currentStyle = nil;
        if ([top respondsToSelector:styleSel]) {
            currentStyle = ((id (*)(id, SEL))objc_msgSend)(top, styleSel);
        }
        
        if (currentStyle && currentStyle == objc_getAssociatedObject(scrollView, &setKey)) return;

        Class effectStyleClass = NSClassFromString(@"UIScrollEdgeEffectStyle");
        SEL softStyleSel = NSSelectorFromString(@"softStyle");
        if (effectStyleClass && [effectStyleClass respondsToSelector:softStyleSel]) {
            id soft = ((id (*)(id, SEL))objc_msgSend)(effectStyleClass, softStyleSel);
            SEL setStyleSel = NSSelectorFromString(@"setStyle:");
            if (soft && [top respondsToSelector:setStyleSel]) {
                ((void (*)(id, SEL, id))objc_msgSend)(top, setStyleSel, soft);
                
                id updatedStyle = [top respondsToSelector:styleSel] ? ((id (*)(id, SEL))objc_msgSend)(top, styleSel) : soft;
                objc_setAssociatedObject(scrollView, &setKey, updatedStyle, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            }
        }
    }
}
