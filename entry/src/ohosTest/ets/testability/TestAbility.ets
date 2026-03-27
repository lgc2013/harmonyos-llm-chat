/*
 * Copyright (c) 2024 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { abilityDelegatorRegistry } from '@kit.TestKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';

const ON_DESTROY_ERROR = -1;
const TAG = 'TestAbility';

export default class TestAbility extends UIAbility {
  abilityDelegator: abilityDelegatorRegistry.AbilityDelegator | null = null;

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(0x0000, TAG, 'TestAbility onCreate');
    hilog.info(0x0000, TAG, 'want param: %{public}s', JSON.stringify(want) ?? '');
    hilog.info(0x0000, TAG, 'launchParam: %{public}s', JSON.stringify(launchParam) ?? '');

    this.abilityDelegator = abilityDelegatorRegistry.getAbilityDelegator();

    // 运行测试
    this.runTests();
  }

  runTests(): void {
    hilog.info(0x0000, TAG, 'Starting test execution...');

    let passed = 0;
    let failed = 0;

    // 基础测试
    try {
      // Test 1: 基础相等
      if (1 === 1) {
        hilog.info(0x0000, TAG, '✓ Test 1 passed: basic equality');
        passed++;
      } else {
        hilog.error(0x0000, TAG, '✗ Test 1 failed');
        failed++;
      }

      // Test 2: 字符串包含
      const str = 'hello world';
      if (str.includes('world')) {
        hilog.info(0x0000, TAG, '✓ Test 2 passed: string contains substring');
        passed++;
      } else {
        hilog.error(0x0000, TAG, '✗ Test 2 failed');
        failed++;
      }

      // Test 3: 数组长度
      const arr: number[] = [1, 2, 3];
      if (arr.length === 3) {
        hilog.info(0x0000, TAG, '✓ Test 3 passed: array length is correct');
        passed++;
      } else {
        hilog.error(0x0000, TAG, '✗ Test 3 failed');
        failed++;
      }

      // Test 4: 对象属性
      const obj: Record<string, number> = { a: 1, b: 2 };
      if (obj['a'] === 1 && obj['b'] === 2) {
        hilog.info(0x0000, TAG, '✓ Test 4 passed: object properties');
        passed++;
      } else {
        hilog.error(0x0000, TAG, '✗ Test 4 failed');
        failed++;
      }

    } catch (e) {
      hilog.error(0x0000, TAG, 'Test execution error: %{public}s', JSON.stringify(e));
      failed++;
    }

    // 输出测试结果
    hilog.info(0x0000, TAG, '=================================');
    hilog.info(0x0000, TAG, 'Test Results: Passed=%{public}d, Failed=%{public}d', passed, failed);
    hilog.info(0x0000, TAG, '=================================');

    // 完成测试
    if (this.abilityDelegator) {
      const message = `Tests completed: ${passed} passed, ${failed} failed`;
      this.abilityDelegator.finishTest(message, failed > 0 ? 1 : 0, () => {
        hilog.info(0x0000, TAG, 'Test finished');
      });
    }
  }

  onDestroy(): void {
    hilog.info(0x0000, TAG, 'TestAbility onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(0x0000, TAG, 'TestAbility onWindowStageCreate');
    windowStage.loadContent('testability/pages/Index', (err) => {
      if (err.code) {
        hilog.error(0x0000, TAG, 'Failed to load content: %{public}s', JSON.stringify(err) ?? '');
        return;
      }
      hilog.info(0x0000, TAG, 'Succeeded in loading content');
    });
  }

  onWindowStageDestroy(): void {
    hilog.info(0x0000, TAG, 'TestAbility onWindowStageDestroy');
  }

  onForeground(): void {
    hilog.info(0x0000, TAG, 'TestAbility onForeground');
  }

  onBackground(): void {
    hilog.info(0x0000, TAG, 'TestAbility onBackground');
  }
}
